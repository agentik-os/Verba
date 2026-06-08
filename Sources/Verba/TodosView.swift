import SwiftUI

// MARK: - Agent: turn a spoken request into a project of tasks (+ sub-tasks)

enum TodoAgent {
    struct Draft { var name: String; var tasks: [(String, [String], Date?)] }
    enum Err: LocalizedError {
        case empty, unparseable
        var errorDescription: String? {
            switch self {
            case .empty: return "Say what the list is for first."
            case .unparseable: return "The agent didn't return a usable list."
            }
        }
    }

    private static var system: String {
        """
        You build a structured to-do list from a request. The user describes what they want \
        (e.g. "a shopping list for a raclette dinner", "steps to launch my landing page", \
        "a project Kitchen, in it a task Chocolate cake, and give me the full shopping list for it"). \
        Turn it into ONE project organized as a hierarchy.

        THREE-LEVEL MODEL — map the user's described structure intelligently:
          • PROJECT — the named bucket (the "project" field).
          • TASK — an actionable item or category inside the project (entries in "tasks").
          • SUBTASK — a smaller step / list item under a task (entries in its "subtasks").
        If the user nests deeper than three levels, FOLD sensibly: the intermediate category \
        becomes the TASK and the leaf actions become its SUBTASKS. If the user names a project and \
        a single task inside it, emit exactly that project with that one task — do NOT split the \
        task into several sibling tasks.

        BE GENERATIVE — this is the most important rule. When the user asks you to PRODUCE or \
        FILL IN a list ("give me the full shopping list for a chocolate cake", "fais-moi toute la \
        liste de courses pour un gâteau au chocolat", "list the steps to…", "what do I need for…"), \
        you MUST GENERATE the actual concrete items from your own knowledge and put them as the \
        SUBTASKS of the relevant task. NEVER just echo the user's sentence back as a single task or \
        subtask. For a chocolate-cake shopping list, real ingredients with rough quantities: flour, \
        sugar, eggs, dark chocolate, butter, baking powder, etc. Produce a complete, useful list \
        (typically 5-15 items) just as a knowledgeable assistant would.

        Reply with a SINGLE JSON object, nothing else (no prose, no code fence):
        {"project":"short project name","tasks":[{"title":"task","due":"2026-06-12T15:00:00+02:00","subtasks":["generated item","generated item"]}]}

        WORKED EXAMPLE (input ≈ "a project Kitchen, in it a task Chocolate cake, and give me the \
        full shopping list for the cake"):
        {"project":"Kitchen","tasks":[{"title":"Chocolate cake","subtasks":["Flour (250 g)","Sugar (200 g)","Eggs (4)","Dark chocolate (200 g)","Butter (150 g)","Baking powder (1 tsp)","Pinch of salt","Vanilla extract"]}]}

        Each task MAY include a "due" field: an ISO8601 date-time WITH timezone offset, but ONLY when \
        the user clearly states a deadline for that task (e.g. "friday at 3pm", "tomorrow 9am", \
        "le 12 à midi"). Resolve relative dates against the context below. Omit "due" entirely when no \
        deadline is mentioned — never invent one.

        \(nowContext())

        Keep titles short and imperative. Detect the user's language and write ALL output in that \
        one language only — never mix languages (a French request → French project, tasks AND \
        generated items).
        """
    }

    /// Current date/time + timezone, given to the model so it can resolve relative deadlines.
    private static func nowContext() -> String {
        let f = ISO8601DateFormatter(); f.timeZone = .current
        let tz = TimeZone.current
        return "CONTEXT — TODAY is \(f.string(from: Date())) (timezone \(tz.identifier), " +
               "current UTC offset \(tz.secondsFromGMT() / 3600)h). Resolve \"friday\", \"tomorrow\", " +
               "\"next week\", times like \"3pm\"/\"15h\" relative to this."
    }

    static func generate(from description: String) async throws -> Draft {
        let desc = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !desc.isEmpty else { throw Err.empty }
        let model = Settings.shared.claudeModel.hasPrefix("claude-") ? Settings.shared.claudeModel : "claude-sonnet-4-6"
        let raw = try await Reprompter(model: model).reprompt(transcript: desc, systemPrompt: system)
        // Never fail with "didn't return a usable list": if parsing the model output fails,
        // still capture the request as a single-task project so nothing is lost.
        if let draft = try? parse(raw), !draft.tasks.isEmpty { return draft }
        return Draft(name: shortName(from: desc), tasks: [(desc, [], nil)])
    }

    /// A short (≤4 word) project name derived from free text, for fallbacks.
    private static func shortName(from text: String) -> String {
        let words = text.split { $0 == " " || $0 == "\n" }.prefix(4).joined(separator: " ")
        return words.isEmpty ? "New list" : String(words)
    }

    static func parse(_ text: String) throws -> Draft {
        var s = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let open = s.range(of: "{"), let close = s.range(of: "}", options: .backwards), open.lowerBound <= close.lowerBound {
            s = String(s[open.lowerBound...close.lowerBound])
        }
        guard let data = s.data(using: .utf8),
              let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { throw Err.unparseable }
        let name = (obj["project"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let rawTasks = obj["tasks"] as? [Any] ?? []
        let tasks = parseTasks(rawTasks)
        guard let name, !name.isEmpty, !tasks.isEmpty else { throw Err.unparseable }
        return Draft(name: name, tasks: tasks)
    }

    /// Shared task-list parser: `[{title, subtasks:[...], due}, …]` → `[(title, [subtask], deadline?)]`.
    static func parseTasks(_ raw: [Any]) -> [(String, [String], Date?)] {
        raw.compactMap { item in
            guard let t = item as? [String: Any], let title = (t["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty else { return nil }
            let subs = (t["subtasks"] as? [Any])?.compactMap { ($0 as? String)?.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } ?? []
            let due = (t["due"] as? String).flatMap(parseDue)
            return (title, subs, due)
        }
    }

    /// Parse an ISO8601 "due" string (with or without fractional seconds) into a Date.
    static func parseDue(_ s: String) -> Date? {
        let str = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !str.isEmpty else { return nil }
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: str) { return d }
        f.formatOptions = [.withInternetDateTime]
        if let d = f.date(from: str) { return d }
        // Date-only ("2026-06-12") → treat as that day, local midnight.
        f.formatOptions = [.withFullDate]
        f.timeZone = .current
        return f.date(from: str)
    }

    // MARK: - Routing: understand the project▸task▸subtask model and place a spoken request

    /// One project the routing agent decided to add tasks to: either an EXISTING project
    /// (by id) or a NEW project (by name), with the tasks (and optional sub-tasks) to append.
    struct ProjectOp {
        var existingProjectID: UUID?     // non-nil → append to this existing project
        var newProjectName: String?      // non-nil → create a project with this name
        var tasks: [(String, [String], Date?)]
    }

    /// What the routing agent decided for a whole spoken request: a LIST of project operations
    /// (one per distinct project the user mentioned) plus any existing items to mark done.
    struct Plan {
        var projectOps: [ProjectOp] = []     // one entry per project to add tasks to
        var completions: [Completion] = []   // existing items the user reported as done
    }

    /// An existing task (or one of its sub-tasks) the agent resolved to mark DONE.
    struct Completion {
        var taskID: UUID
        var subtaskID: UUID?             // non-nil → mark this sub-task done, not the whole task
    }

    private static var routeSystem: String {
        """
        You route a spoken request into a hierarchical to-do model:
          • PROJECT — a named bucket (e.g. "Groceries", "Launch", "Trip to Rome")
          • TASK — one actionable item or category inside a project (e.g. "Buy milk", "Chocolate cake")
          • SUBTASK — a smaller step / list item under a task; add sub-tasks when a task naturally \
        breaks down OR when the user asks you to generate a list (see GENERATIVE below), otherwise \
        leave subtasks empty.

        HIERARCHY — map the user's described nesting into these three levels intelligently. A single \
        request can create one or more PROJECTS, each with TASKS, each task with SUBTASKS. If the \
        user nests deeper than three levels, FOLD sensibly: the intermediate category becomes the \
        TASK and the leaf actions become its SUBTASKS. If the user names a project and a single task \
        inside it, emit exactly that project with that one task — don't split it into siblings.

        GENERATIVE — when the user asks you to PRODUCE or FILL IN a list ("give me the full shopping \
        list for a chocolate cake", "fais-moi toute la liste de courses pour un gâteau au chocolat", \
        "list the steps to…", "what do I need for…"), GENERATE the actual concrete items from your \
        own knowledge and put them as the SUBTASKS of the relevant task. NEVER just echo the user's \
        sentence back. For a chocolate-cake shopping list: real ingredients with rough quantities \
        (flour, sugar, eggs, dark chocolate, butter, baking powder, …). Produce a complete, useful \
        list (typically 5-15 items).
        WORKED EXAMPLE — "fais un projet Cuisine, dans Cuisine une tâche Gâteau au chocolat, et \
        fais-moi toute la liste de courses pour le gâteau au chocolat":
        {"projects":[{"new_project":"Cuisine","tasks":[{"title":"Gâteau au chocolat","subtasks":["Farine (250 g)","Sucre (200 g)","Œufs (4)","Chocolat noir (200 g)","Beurre (150 g)","Levure chimique (1 c. à café)","Pincée de sel","Extrait de vanille"]}]}]}

        You are given the user's EXISTING projects with their tasks and sub-tasks. Decide what the \
        request means:

        1. COMPLETION — the user is REPORTING that they already did something that matches an \
        existing task or sub-task (e.g. "j'ai acheté des tomates", "I bought tomatoes", "done with \
        the groceries", "j'ai fini la liste de courses"). Identify the matching EXISTING item(s) and \
        return them under "complete" so they get checked off. Match by intent against the titles in \
        the EXISTING PROJECTS list below — DO NOT add new tasks for something already there.
        2. ADD — the user wants to add NEW item(s), possibly across SEVERAL projects in one request. \
        A single request MAY contain BOTH (e.g. "j'ai acheté le lait, ajoute du pain") — then return \
        "complete" AND "projects" together.

        For ADD: extract EVERY distinct project the user mentions and emit ONE entry per project under \
        "projects". For each project decide whether it belongs to an existing project (match by name \
        or intent — e.g. "to my groceries" → an existing "Groceries" project) or needs a NEW project. \
        Prefer reusing an existing project when the intent clearly matches; only create a new project \
        when none fits. If the user clearly asks for two (or more) projects, you MUST emit two (or \
        more) "projects" entries — never collapse them into one.

        Reply with a SINGLE JSON object, nothing else (no prose, no code fence). It may contain any of:
          • "complete": items to mark done, each {"project":"<existing project name>","task":"<existing task title>","subtask":"<optional existing sub-task title>"}
          • "projects": a LIST of project operations, each either
                {"existing_project":"<exact existing project name>","tasks":[…]}   (add to an existing project)
                {"new_project":"short project name","tasks":[…]}                     (add to a new project)
        Each task in "tasks" is {"title":"task","due":"2026-06-12T15:00:00+02:00","subtasks":["optional"]}.
        Examples:
          report done:   {"complete":[{"project":"Groceries","task":"Buy tomatoes"}]}
          add (one):     {"projects":[{"existing_project":"Groceries","tasks":[{"title":"Buy bread"}]}]}
          add (two new): {"projects":[{"new_project":"Groceries","tasks":[{"title":"Buy tomatoes"},{"title":"Buy pasta"}]},{"new_project":"Work","tasks":[{"title":"Finish the report"}]}]}
          fr (deux):     "deux projets: courses avec tomates et pâtes, et boulot avec finir le rapport" → {"projects":[{"new_project":"Courses","tasks":[{"title":"Acheter des tomates"},{"title":"Acheter des pâtes"}]},{"new_project":"Boulot","tasks":[{"title":"Finir le rapport"}]}]}
          both:          {"complete":[{"project":"Groceries","task":"Buy milk"}],"projects":[{"existing_project":"Groceries","tasks":[{"title":"Buy bread"}]}]}

        For "complete", use the EXACT task/sub-task titles as they appear in the EXISTING PROJECTS \
        list. Set "subtask" only when reporting a single sub-task done; omit it to complete the whole \
        task. If nothing matches, do not invent a completion.

        Each task MAY include a "due" field: an ISO8601 date-time WITH timezone offset, but ONLY when \
        the user clearly states a deadline for that task (e.g. "friday at 3pm", "tomorrow 9am", \
        "le 12 à midi"). Resolve relative dates against the context below. Omit "due" entirely when no \
        deadline is mentioned — never invent one.

        \(nowContext())

        Use "existing_project" only with a name that appears verbatim in the provided list; \
        otherwise use "new_project". Keep task titles short and imperative. Extract every distinct \
        item the user mentioned (e.g. "milk and eggs" → two tasks) and every distinct project. \
        Detect the user's language and write ALL output in that one language only — never mix \
        languages.
        """
    }

    /// Route a transcript into a `Plan` against the user's existing projects.
    static func route(transcript: String, projects: [TodoProject]) async throws -> Plan {
        let desc = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !desc.isEmpty else { throw Err.empty }
        let list = projectsContext(projects)
        let sys = routeSystem + "\n\nEXISTING PROJECTS:\n\(list)"
        let model = Settings.shared.claudeModel.hasPrefix("claude-") ? Settings.shared.claudeModel : "claude-sonnet-4-6"
        let raw = try await Reprompter(model: model).reprompt(transcript: desc, systemPrompt: sys)
        // Never drop the user's spoken to-do: if the agent's output can't be parsed into a
        // plan, file it as one task in an "Inbox" project (reusing one if it already exists).
        // A pure-completion plan (no new tasks but ≥1 resolved completion) is valid too.
        if let plan = try? parsePlan(raw, projects: projects),
           !plan.projectOps.isEmpty || !plan.completions.isEmpty { return plan }
        let inbox = projects.first { $0.name.caseInsensitiveCompare("Inbox") == .orderedSame }
        let op = ProjectOp(existingProjectID: inbox?.id,
                           newProjectName: inbox == nil ? "Inbox" : nil,
                           tasks: [(desc, [], nil)])
        return Plan(projectOps: [op])
    }

    /// Compact list of the user's projects WITH their task / sub-task titles, for the route prompt.
    /// Capped so a large board stays within a sane prompt size.
    private static func projectsContext(_ projects: [TodoProject]) -> String {
        let valid = projects.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        guard !valid.isEmpty else { return "(none yet)" }
        var lines: [String] = []
        for p in valid.prefix(20) {
            lines.append("- \(p.name)")
            for t in p.tasks.prefix(30) where !t.title.trimmingCharacters(in: .whitespaces).isEmpty {
                let mark = t.done ? " [done]" : ""
                lines.append("    • \(t.title)\(mark)")
                for s in t.subtasks.prefix(15) where !s.title.trimmingCharacters(in: .whitespaces).isEmpty {
                    lines.append("        - \(s.title)\(s.done ? " [done]" : "")")
                }
            }
        }
        return lines.joined(separator: "\n")
    }

    static func parsePlan(_ text: String, projects: [TodoProject]) throws -> Plan {
        var s = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let open = s.range(of: "{"), let close = s.range(of: "}", options: .backwards), open.lowerBound <= close.lowerBound {
            s = String(s[open.lowerBound...close.lowerBound])
        }
        guard let data = s.data(using: .utf8),
              let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { throw Err.unparseable }
        let completions = parseCompletions(obj["complete"] as? [Any] ?? [], projects: projects)

        // Gather the per-project ADD entries. New schema: a "projects" list of objects, each
        // {existing_project|new_project, tasks:[…]}. Back-compat: a single top-level
        // {existing_project|new_project, tasks:[…]} (old single-project shape) is also accepted.
        var entries = obj["projects"] as? [Any] ?? []
        if entries.isEmpty, obj["tasks"] != nil || obj["existing_project"] != nil || obj["new_project"] != nil {
            entries = [obj]   // treat the whole object as one project entry
        }

        var ops: [ProjectOp] = []
        for entry in entries {
            guard let e = entry as? [String: Any] else { continue }
            let tasks = parseTasks(e["tasks"] as? [Any] ?? [])
            guard !tasks.isEmpty else { continue }

            // Resolve an "existing_project" name to a real project (case-insensitive match);
            // fall back to creating it as a new project if the name doesn't actually exist.
            if let existing = (e["existing_project"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !existing.isEmpty {
                if let match = projects.first(where: { $0.name.caseInsensitiveCompare(existing) == .orderedSame }) {
                    ops.append(ProjectOp(existingProjectID: match.id, newProjectName: nil, tasks: tasks))
                } else {
                    ops.append(ProjectOp(existingProjectID: nil, newProjectName: existing, tasks: tasks))
                }
                continue
            }
            if let newName = (e["new_project"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !newName.isEmpty {
                ops.append(ProjectOp(existingProjectID: nil, newProjectName: newName, tasks: tasks))
            }
        }

        // A request can be: add-only, complete-only, or both. It's only unparseable when the
        // agent gave us neither resolvable completions nor any new tasks.
        guard !ops.isEmpty || !completions.isEmpty else { throw Err.unparseable }
        return Plan(projectOps: ops, completions: completions)
    }

    /// Resolve agent-named completions to real TodoTask / TodoSubtask ids by case-insensitive
    /// fuzzy (contains, either direction) matching against the current projects. Unmatched
    /// completions are silently dropped — never crash on a no-match.
    static func parseCompletions(_ raw: [Any], projects: [TodoProject]) -> [Completion] {
        var out: [Completion] = []
        var seen = Set<UUID>()
        let norm: (String) -> String = { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
        let fuzzy: (String, String) -> Bool = { a, b in
            let x = norm(a), y = norm(b)
            guard !x.isEmpty, !y.isEmpty else { return false }
            return x == y || x.contains(y) || y.contains(x)
        }
        for item in raw {
            guard let c = item as? [String: Any] else { continue }
            let projName = (c["project"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let taskName = (c["task"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !taskName.isEmpty else { continue }
            let subName = (c["subtask"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)

            // Restrict to the named project when it resolves; otherwise search all projects.
            let scope: [TodoProject]
            if let projName, !projName.isEmpty,
               let match = projects.first(where: { fuzzy($0.name, projName) }) {
                scope = [match]
            } else {
                scope = projects
            }

            var resolved = false
            for p in scope {
                for t in p.tasks where fuzzy(t.title, taskName) {
                    if let subName, !subName.isEmpty {
                        if let sub = t.subtasks.first(where: { fuzzy($0.title, subName) }) {
                            if seen.insert(sub.id).inserted { out.append(Completion(taskID: t.id, subtaskID: sub.id)) }
                            resolved = true; break
                        }
                    } else {
                        if seen.insert(t.id).inserted { out.append(Completion(taskID: t.id, subtaskID: nil)) }
                        resolved = true; break
                    }
                }
                if resolved { break }
            }
        }
        return out
    }
}

// MARK: - To-dos view (Projects ▸ Tasks ▸ Sub-tasks, accordion)

struct TodosView: View {
    @ObservedObject var store = TodoStore.shared
    @ObservedObject private var capture = TodoCaptureController.shared
    @State private var expandedProjects: Set<UUID> = []
    @State private var expandedTasks: Set<UUID> = []
    @State private var genText = ""
    @State private var genBusy = false
    @State private var genError: String?
    @State private var activeTags: Set<String> = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Task Manager").font(.system(size: 28, weight: .bold))
                    Text("Capture tasks by voice, sorted by project. Dictate into any field, or ask the agent to build a list.")
                        .foregroundStyle(.secondary)
                }

                agentBar

                filterBar

                if store.projects.isEmpty {
                    EmptyState(icon: "checklist", title: "No projects yet",
                               message: "Make a project for anything you need to track (Groceries, Launch, Trip…), then add tasks and sub-tasks. Or describe a list above and the agent builds it for you.")
                }

                ForEach($store.projects) { $project in
                    if matchesFilter(project) {
                        ProjectPanel(
                            project: $project,
                            expanded: projectExpansion(project.id),
                            expandedTasks: $expandedTasks,
                            onDelete: { store.removeProject(project.id) },
                            onAddTask: { store.addTask(project.id) },
                            onRemoveTask: { tid in store.removeTask(project.id, tid) },
                            onAddSubtask: { tid in store.addSubtask(project.id, tid) },
                            onAddTag: { tag in store.addTag(project.id, tag) },
                            onRemoveTag: { tag in store.removeTag(project.id, tag) }
                        )
                    }
                }

                Button {
                    let id = store.addProject(); expandedProjects.insert(id)
                } label: { Label("New project", systemImage: "plus") }
                    .buttonStyle(.borderless)
            }
            .padding(32).frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var agentBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "wand.and.sparkles").foregroundStyle(.secondary)
                TextField("Describe a list… e.g. “shopping list for a raclette dinner”", text: $genText)
                    .textFieldStyle(.plain)
                    .onSubmit(generate)
                if genBusy { ProgressView().controlSize(.small) }
                Button(action: generate) { Text("Build") }
                    .buttonStyle(.borderedProminent)
                    .disabled(genBusy || genText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            if let genError { Text(genError).font(.caption).foregroundStyle(.red) }

            Divider()

            HStack(spacing: 10) {
                Button { capture.requestCapture() } label: {
                    Label(capture.capturing ? "Listening — tap to add" : "Capture by voice",
                          systemImage: capture.capturing ? "stop.circle.fill" : "mic.fill")
                }
                .buttonStyle(.bordered)
                .tint(capture.capturing ? .red : .accentColor)
                if capture.capturing { ProgressView().controlSize(.small) }
                Text("Speak a task and the agent files it under the right project.")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            if let err = capture.lastError { Text(err).font(.caption).foregroundStyle(.red) }
        }
        .cleanCard(padding: 14)
    }

    /// Tag pills to narrow the visible projects. Hidden until at least one tag exists.
    @ViewBuilder private var filterBar: some View {
        let tags = store.allTags
        if !tags.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "line.3.horizontal.decrease.circle").foregroundStyle(.secondary)
                    Text("Filter by tag").font(.caption.weight(.medium)).foregroundStyle(.secondary)
                }
                FlowLayout(spacing: 6) {
                    FilterPill(label: "All", selected: activeTags.isEmpty) { activeTags.removeAll() }
                    ForEach(tags, id: \.self) { tag in
                        FilterPill(label: tag, selected: activeTags.contains(tag)) {
                            if activeTags.contains(tag) { activeTags.remove(tag) } else { activeTags.insert(tag) }
                        }
                    }
                }
            }
            .cleanCard(padding: 12)
        }
    }

    /// A project is visible when no live tags are selected, or it bears any selected tag.
    /// Intersecting with the current tag set self-heals selections whose tag was deleted.
    private func matchesFilter(_ project: TodoProject) -> Bool {
        let live = activeTags.intersection(Set(store.allTags))
        if live.isEmpty { return true }
        let projTags = Set(project.tags.map { $0.lowercased() })   // case-insensitive, matches allTags dedupe
        return live.contains { projTags.contains($0.lowercased()) }
    }

    private func generate() {
        let desc = genText
        guard !desc.trimmingCharacters(in: .whitespaces).isEmpty, !genBusy else { return }
        genError = nil; genBusy = true
        Task {
            do {
                let d = try await TodoAgent.generate(from: desc)
                await MainActor.run {
                    store.addGenerated(name: d.name, tasks: d.tasks)
                    if let id = store.projects.last?.id { expandedProjects.insert(id) }
                    genText = ""; genBusy = false
                }
            } catch {
                await MainActor.run { genError = error.localizedDescription; genBusy = false }
            }
        }
    }

    /// A Binding<Bool> for whether project `id` is expanded.
    private func projectExpansion(_ id: UUID) -> Binding<Bool> {
        Binding(get: { expandedProjects.contains(id) },
                set: { if $0 { expandedProjects.insert(id) } else { expandedProjects.remove(id) } })
    }
}

// MARK: - Project panel (accordion)

private struct ProjectPanel: View {
    @Binding var project: TodoProject
    @Binding var expanded: Bool
    @Binding var expandedTasks: Set<UUID>
    let onDelete: () -> Void
    let onAddTask: () -> Void
    let onRemoveTask: (UUID) -> Void
    let onAddSubtask: (UUID) -> Void
    let onAddTag: (String) -> Void
    let onRemoveTag: (String) -> Void

    @State private var tagDraft = ""
    @State private var addingTag = false

    private var prog: (done: Int, total: Int) { TodoStore.shared.progress(project) }

    /// Removable tag chips plus an "Add tag" affordance, shown inline on the project title line.
    /// Horizontally scrollable so many tags never push the title off-screen.
    private var tagsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(project.tags, id: \.self) { tag in
                    HStack(spacing: 5) {
                        Text(tag).font(.caption)
                        Button { onRemoveTag(tag) } label: { Image(systemName: "xmark.circle.fill") }
                            .buttonStyle(.plain).foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 9).padding(.vertical, 5)
                    .background(.softFill, in: Capsule())
                }
                if addingTag {
                    HStack(spacing: 4) {
                        Image(systemName: "tag").font(.caption2).foregroundStyle(.secondary)
                        TextField("Tag", text: $tagDraft)
                            .textFieldStyle(.plain).font(.caption).frame(width: 80)
                            .onSubmit(commitTag)
                        Button { commitTag() } label: { Image(systemName: "checkmark.circle.fill") }
                            .buttonStyle(.plain).foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 9).padding(.vertical, 5)
                    .background(.softFill, in: Capsule())
                } else {
                    Button { addingTag = true } label: {
                        Label("Add tag", systemImage: "plus").font(.caption)
                    }
                    .buttonStyle(.plain).foregroundStyle(.secondary)
                    .padding(.horizontal, 9).padding(.vertical, 5)
                    .background(.softFill, in: Capsule())
                }
            }
            .padding(.vertical, 1)
        }
    }

    private func commitTag() {
        let t = tagDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !t.isEmpty { onAddTag(t) }
        tagDraft = ""; addingTag = false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Button { withAnimation(.easeInOut(duration: 0.18)) { expanded.toggle() } } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
                        .rotationEffect(.degrees(expanded ? 90 : 0)).frame(width: 16)
                }.buttonStyle(.plain)
                Image(systemName: "folder").foregroundStyle(.secondary)
                TextField("Project", text: $project.name).textFieldStyle(.plain).font(.headline)
                    .frame(minWidth: 80, idealWidth: 160)
                    .layoutPriority(1)
                tagsRow
                Spacer(minLength: 8)
                if prog.total > 0 {
                    Text("\(prog.done)/\(prog.total)")
                        .font(.caption.weight(.medium)).foregroundStyle(.secondary)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(.softFill, in: Capsule())
                }
                Button(role: .destructive, action: onDelete) { Image(systemName: "trash") }
                    .buttonStyle(.borderless).foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)

            if expanded {
                VStack(spacing: 8) {
                    ForEach($project.tasks) { $task in
                        TaskPanel(
                            task: $task,
                            expanded: Binding(get: { expandedTasks.contains(task.id) },
                                              set: { if $0 { expandedTasks.insert(task.id) } else { expandedTasks.remove(task.id) } }),
                            onDelete: { onRemoveTask(task.id) },
                            onAddSubtask: { onAddSubtask(task.id) }
                        )
                    }
                    Button(action: onAddTask) { Label("Add task", systemImage: "plus") }
                        .buttonStyle(.borderless).font(.callout)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 8).padding(.leading, 26)
            }
        }
        .cleanCard(padding: 16)
    }
}

// MARK: - Filter pill (toggleable tag in the filter bar)

private struct FilterPill: View {
    let label: String
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label).font(.caption.weight(.medium))
                .foregroundStyle(selected ? AnyShapeStyle(.white) : AnyShapeStyle(.secondary))
                .padding(.horizontal, 11).padding(.vertical, 5)
                .background(selected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.softFill), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Deadline picker (reusable, used by tasks and sub-tasks)

/// A clean, modern date+time deadline control bound to a `Date?`.
/// Renders a capsule trigger (showing the deadline or a "＋ Deadline" hint)
/// and a popover with quick-preset chips plus a framed calendar + time editor.
private struct DeadlinePicker: View {
    @Binding var deadline: Date?
    /// Whether the owning item is done — suppresses the overdue (red) styling.
    var isDone: Bool = false
    /// Compact trigger for sub-task rows (smaller text, "Due" instead of "Deadline").
    var compact: Bool = false

    @State private var show = false

    /// True when there is a deadline in the past and the item isn't done.
    private var overdue: Bool {
        guard let d = deadline, !isDone else { return false }
        return d < Date()
    }

    /// Compact label, e.g. "Fri 15:00" (or "Jun 12, 15:00" when far off).
    private func label(_ d: Date) -> String {
        let cal = Calendar.current
        let f = DateFormatter()
        f.locale = Locale.current
        if let days = cal.dateComponents([.day], from: cal.startOfDay(for: Date()), to: cal.startOfDay(for: d)).day,
           days >= 0, days <= 6 {
            f.dateFormat = "EEE HH:mm"
        } else {
            f.dateFormat = "MMM d, HH:mm"
        }
        return f.string(from: d)
    }

    var body: some View {
        Button { show = true } label: {
            if let d = deadline {
                HStack(spacing: 3) {
                    Image(systemName: "clock").font(.system(size: compact ? 9 : 10))
                    Text(label(d)).font((compact ? Font.caption2 : Font.caption2).weight(.medium))
                }
                .foregroundStyle(overdue ? AnyShapeStyle(.red) : AnyShapeStyle(.secondary))
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(.softFill, in: Capsule())
            } else {
                Label(compact ? "Due" : "Deadline", systemImage: "plus")
                    .font(.caption2).foregroundStyle(.tertiary)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(.softFill, in: Capsule())
            }
        }
        .buttonStyle(.plain)
        .help(deadline == nil ? "Set a deadline" : "Edit deadline")
        .popover(isPresented: $show, arrowEdge: .bottom) { popover }
    }

    // MARK: presets

    /// Quick-pick chips that map to sensible future dates.
    private func presets() -> [(String, Date?)] {
        let cal = Calendar.current
        let now = Date()
        func at(_ base: Date, hour: Int, minute: Int = 0) -> Date {
            cal.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? base
        }
        // Today 6pm — if already past, roll to tomorrow 6pm so it stays in the future.
        var today6 = at(now, hour: 18)
        if today6 <= now { today6 = at(cal.date(byAdding: .day, value: 1, to: now) ?? now, hour: 18) }
        let tomorrow9 = at(cal.date(byAdding: .day, value: 1, to: now) ?? now, hour: 9)
        // This weekend → upcoming Saturday 10am.
        let weekday = cal.component(.weekday, from: now) // 1 = Sunday … 7 = Saturday
        let daysToSat = (7 - weekday + 7) % 7   // 0 if today is Saturday
        let satBase = cal.date(byAdding: .day, value: daysToSat == 0 ? 7 : daysToSat, to: now) ?? now
        let weekend = at(satBase, hour: 10)
        let nextWeek = at(cal.date(byAdding: .day, value: 7, to: now) ?? now, hour: 9)
        return [
            ("Today 6pm", today6),
            ("Tomorrow 9am", tomorrow9),
            ("This weekend", weekend),
            ("Next week", nextWeek),
            ("Clear", nil)
        ]
    }

    private var popover: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Deadline").font(.headline)

            // Quick presets
            PresetChipRows(items: presets()) { title, date in
                ChipButton(title: title, isClear: date == nil) {
                    deadline = date
                    if date == nil { show = false }
                }
            }

            // Framed date + time editor (both day and hour/minute).
            DatePicker(
                "",
                selection: Binding(get: { deadline ?? defaultPickerDate() }, set: { deadline = $0 }),
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
            .frame(width: 280)
            .cleanCard(padding: 10)

            HStack {
                Button("Clear") { deadline = nil; show = false }
                    .disabled(deadline == nil)
                Spacer()
                Button("Done") { show = false }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .frame(width: 320)
    }

    /// A reasonable default when no deadline is set yet (today, 9am or next hour).
    private func defaultPickerDate() -> Date {
        let cal = Calendar.current
        let nine = cal.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        return nine > Date() ? nine : (cal.date(byAdding: .hour, value: 1, to: Date()) ?? Date())
    }
}

/// On-brand preset chip.
private struct ChipButton: View {
    let title: String
    var isClear: Bool = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(isClear ? AnyShapeStyle(.red) : AnyShapeStyle(.secondary))
                .padding(.horizontal, 11).padding(.vertical, 5)
                .background(.softFill, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Simple two-row layout for the deadline preset chips.
private struct PresetChipRows<Content: View>: View {
    let items: [(String, Date?)]
    @ViewBuilder let content: (String, Date?) -> Content

    var body: some View {
        // Two rows of chips keeps the popover compact and tidy.
        let half = (items.count + 1) / 2
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) { ForEach(0..<half, id: \.self) { content(items[$0].0, items[$0].1) } }
            HStack(spacing: 8) { ForEach(half..<items.count, id: \.self) { content(items[$0].0, items[$0].1) } }
        }
    }
}

// MARK: - Task panel (accordion, holds sub-tasks)

private struct TaskPanel: View {
    @Binding var task: TodoTask
    @Binding var expanded: Bool
    let onDelete: () -> Void
    let onAddSubtask: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 9) {
                Button { task.done.toggle() } label: {
                    Image(systemName: task.done ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(task.done ? AnyShapeStyle(.green) : AnyShapeStyle(.secondary))
                }.buttonStyle(.plain)
                TextField("Task", text: $task.title).textFieldStyle(.plain)
                    .strikethrough(task.done, color: .secondary)
                    .foregroundStyle(task.done ? .secondary : .primary)
                Spacer(minLength: 6)
                DeadlinePicker(deadline: $task.deadline, isDone: task.done)
                Button { withAnimation(.easeInOut(duration: 0.18)) { expanded.toggle() } } label: {
                    HStack(spacing: 3) {
                        if !task.subtasks.isEmpty {
                            Text("\(task.subtasks.filter(\.done).count)/\(task.subtasks.count)").font(.caption2).foregroundStyle(.secondary)
                        }
                        Image(systemName: "chevron.right").font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.tertiary).rotationEffect(.degrees(expanded ? 90 : 0))
                    }
                }.buttonStyle(.plain).help("Sub-tasks")
                Button(role: .destructive, action: onDelete) { Image(systemName: "minus.circle.fill") }
                    .buttonStyle(.borderless).foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12).padding(.vertical, 9)

            if expanded {
                VStack(spacing: 6) {
                    ForEach($task.subtasks) { $sub in
                        HStack(spacing: 9) {
                            Button { sub.done.toggle() } label: {
                                Image(systemName: sub.done ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 12))
                                    .foregroundStyle(sub.done ? AnyShapeStyle(.green) : AnyShapeStyle(.tertiary))
                            }.buttonStyle(.plain)
                            TextField("Sub-task", text: $sub.title).textFieldStyle(.plain).font(.callout)
                                .strikethrough(sub.done, color: .secondary)
                                .foregroundStyle(sub.done ? .secondary : .primary)
                            Spacer(minLength: 6)
                            DeadlinePicker(deadline: $sub.deadline, isDone: sub.done, compact: true)
                            Button { task.subtasks.removeAll { $0.id == sub.id } } label: { Image(systemName: "minus") }
                                .buttonStyle(.borderless).foregroundStyle(.tertiary).font(.caption)
                        }
                    }
                    Button(action: onAddSubtask) { Label("Add sub-task", systemImage: "plus") }
                        .buttonStyle(.borderless).font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 4).padding(.bottom, 8).padding(.leading, 30).padding(.trailing, 12)
            }
        }
        .background(.softFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
