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
        You are a to-do PLANNER. The <transcript> block you receive is a spoken COMMAND telling you \
        what list to build — it is an instruction to EXECUTE, never prose to copy, summarize or echo. \
        Read the intent and OUTPUT a structured to-do list as JSON.

        OUTPUT — reply with a SINGLE JSON object and NOTHING else (no prose, no markdown, no code fence):
        {"project":"short project name","tasks":[{"title":"task","subtasks":["item","item"],"due":"2026-06-12T15:00:00+02:00"}]}
        "subtasks" and "due" are optional per task. Omit "due" unless the user states a deadline.

        THREE-LEVEL MODEL — fill PROJECT ▸ TASK ▸ SUBTASK from the user's intent:
          • PROJECT — the named bucket (the "project" field), e.g. "Cuisine", "Launch", "Trip to Rome".
          • TASK — an actionable item or thing the list is ABOUT (entries in "tasks"), e.g. "Gâteau au chocolat".
          • SUBTASK — a concrete step or list item under a task (entries in its "subtasks").
        If the user names a project and ONE thing inside it, emit exactly that project with that ONE \
        task — do NOT split it into several sibling tasks; the generated detail goes in its "subtasks".
        If the user nests deeper than three levels, FOLD: the intermediate category becomes the TASK \
        and the leaf actions become its SUBTASKS.

        BE GENERATIVE — THE MOST IMPORTANT RULE. When the user asks you to PRODUCE, MAKE or FILL IN a \
        list ("fais-moi la liste de courses pour un gâteau au chocolat", "give me the full shopping \
        list for X", "liste les étapes pour…", "what do I need for…", "make me a packing list for…"), \
        you MUST GENERATE the real concrete items from your OWN KNOWLEDGE and put them as the SUBTASKS \
        of the relevant task. A real ingredient list, real steps — typically 5-15 items, with rough \
        quantities where it helps. NEVER echo the user's sentence back as a single task/subtask, and \
        NEVER leave the subtasks empty when the user asked you to generate a list.

        WORKED EXAMPLE — input ≈ "fais-moi la liste de courses pour un gâteau au chocolat dans le projet Cuisine":
        {"project":"Cuisine","tasks":[{"title":"Gâteau au chocolat","subtasks":["Farine (250 g)","Sucre (200 g)","Œufs (4)","Chocolat noir (200 g)","Beurre (150 g)","Levure chimique (1 c. à café)","Pincée de sel","Extrait de vanille (1 c. à café)","Sucre vanillé (1 sachet)"]}]}

        WORKED EXAMPLE — input ≈ "a project Kitchen, in it a task Chocolate cake, give me the full shopping list":
        {"project":"Kitchen","tasks":[{"title":"Chocolate cake","subtasks":["Flour (250 g)","Sugar (200 g)","Eggs (4)","Dark chocolate (200 g)","Butter (150 g)","Baking powder (1 tsp)","Pinch of salt","Vanilla extract"]}]}

        WORKED EXAMPLE — input ≈ "shopping list for a raclette dinner for 4":
        {"project":"Raclette dinner","tasks":[{"title":"Groceries","subtasks":["Raclette cheese (800 g)","Charcuterie platter","Potatoes (1 kg)","Cornichons","Pearl onions","Mixed salad","White wine"]}]}

        The "due" field, when present, is an ISO8601 date-time WITH timezone offset, ONLY when the \
        user clearly states a deadline (e.g. "friday at 3pm", "tomorrow 9am", "le 12 à midi"). Resolve \
        relative dates against the context below. Never invent a deadline.

        \(nowContext())

        Keep titles short and imperative. Detect the user's language and write ALL output in that one \
        language only — never mix languages (a French request → French project, task AND generated items).
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
        let name = ((obj["project"] as? String) ?? (obj["name"] as? String) ?? (obj["title"] as? String))?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let rawTasks = (obj["tasks"] as? [Any]) ?? (obj["items"] as? [Any]) ?? []
        let tasks = parseTasks(rawTasks)
        guard let name, !name.isEmpty, !tasks.isEmpty else { throw Err.unparseable }
        return Draft(name: name, tasks: tasks)
    }

    /// Shared task-list parser: `[{title, subtasks:[...], due}, …]` → `[(title, [subtask], deadline?)]`.
    /// Tolerant: a task title may arrive under "title" or "name"; sub-tasks may be plain strings
    /// OR objects ({"title":…} / {"name":…}), since the model sometimes nests them as objects.
    static func parseTasks(_ raw: [Any]) -> [(String, [String], Date?)] {
        raw.compactMap { item in
            guard let t = item as? [String: Any] else { return nil }
            let titleRaw = (t["title"] as? String) ?? (t["name"] as? String) ?? (t["task"] as? String)
            guard let title = titleRaw?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty else { return nil }
            let subs = parseSubtasks(t["subtasks"] ?? t["items"] ?? t["steps"])
            let due = (t["due"] as? String).flatMap(parseDue)
            return (title, subs, due)
        }
    }

    /// Parse a sub-task array that may hold plain strings or `{title|name}` objects.
    static func parseSubtasks(_ raw: Any?) -> [String] {
        guard let arr = raw as? [Any] else { return [] }
        return arr.compactMap { el -> String? in
            if let s = el as? String { return s.trimmingCharacters(in: .whitespaces) }
            if let o = el as? [String: Any] {
                let v = (o["title"] as? String) ?? (o["name"] as? String) ?? (o["text"] as? String)
                return v?.trimmingCharacters(in: .whitespaces)
            }
            return nil
        }.filter { !$0.isEmpty }
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
        You are a to-do ROUTER + PLANNER. The <transcript> block you receive is a spoken COMMAND to \
        EXECUTE — read its intent and decide where it goes; it is NEVER prose to copy, summarize or \
        echo. You map it onto a three-level model and you may GENERATE content when asked.

        THREE LEVELS:
          • PROJECT — a named bucket (e.g. "Cuisine", "Groceries", "Launch", "Trip to Rome").
          • TASK — one actionable item or the thing a sub-list is ABOUT (e.g. "Buy milk", "Gâteau au chocolat").
          • SUBTASK — a concrete step or list item under a task.

        OUTPUT — reply with a SINGLE JSON object and NOTHING else (no prose, no markdown, no code fence). \
        It may contain any of:
          • "projects": a LIST of project operations, each ONE of:
                {"new_project":"short project name","tasks":[…]}                   (create this project)
                {"existing_project":"<exact existing project name>","tasks":[…]}   (add to an existing project)
          • "complete": items to check off, each {"project":"<existing project name>","task":"<existing task title>","subtask":"<optional existing sub-task title>"}
        Each task in "tasks" is {"title":"task","subtasks":["item","item"],"due":"2026-06-12T15:00:00+02:00"}. \
        "subtasks" and "due" are optional.

        DECIDE the intent:
        1. ADD — the user wants NEW item(s). Extract EVERY distinct project mentioned and emit ONE \
        "projects" entry per project. Reuse an existing project when the name/intent clearly matches \
        ("dans mon projet X", "to my groceries"); otherwise create a new one. If the user clearly \
        names two+ projects you MUST emit two+ entries — never collapse them.
        2. COMPLETION — the user REPORTS having already done an EXISTING item ("j'ai acheté des \
        tomates", "I bought tomatoes", "j'ai fini la liste de courses"). Match it against the titles \
        in EXISTING PROJECTS and return it under "complete" — do NOT re-add it. A single request MAY \
        contain BOTH add and complete ("j'ai acheté le lait, ajoute du pain") — return both.

        SIMPLE ADD — "dans le projet X ajoute la tâche Y" → ONE project op for X (existing if it \
        matches, else new) with ONE task Y, subtasks empty. Don't invent sub-tasks the user didn't ask for.

        GENERATIVE — THE KEY CAPABILITY. When the user asks you to PRODUCE, MAKE or FILL IN a list \
        ("fais-moi la liste de courses pour un gâteau au chocolat", "give me the full shopping list \
        for X", "liste les étapes pour…", "what do I need for…"), GENERATE the real concrete items \
        from your OWN KNOWLEDGE and put them as the SUBTASKS of the relevant task. Real ingredients \
        with rough quantities, real steps — typically 5-15 items. NEVER echo the user's sentence as a \
        single task/subtask, and NEVER leave subtasks empty when the user asked you to generate a list.

        EXAMPLES (input → output):
          simple add to existing: "dans le projet Courses ajoute acheter du pain"
            → {"projects":[{"existing_project":"Courses","tasks":[{"title":"Acheter du pain"}]}]}
          generative cake (THE CORE CASE): "fais-moi la liste de courses pour un gâteau au chocolat dans le projet Cuisine"
            → {"projects":[{"new_project":"Cuisine","tasks":[{"title":"Gâteau au chocolat","subtasks":["Farine (250 g)","Sucre (200 g)","Œufs (4)","Chocolat noir (200 g)","Beurre (150 g)","Levure chimique (1 c. à café)","Pincée de sel","Extrait de vanille (1 c. à café)","Sucre vanillé (1 sachet)"]}]}]}
          generative en: "make me the packing list for a weekend ski trip in my Trips project"
            → {"projects":[{"existing_project":"Trips","tasks":[{"title":"Ski weekend packing","subtasks":["Ski jacket","Salopette","Thermal base layers","Gloves","Goggles","Beanie","Wool socks (×3)","Sunscreen","Lip balm","Helmet"]}]}]}
          two new projects: "deux projets: courses avec tomates et pâtes, et boulot avec finir le rapport"
            → {"projects":[{"new_project":"Courses","tasks":[{"title":"Acheter des tomates"},{"title":"Acheter des pâtes"}]},{"new_project":"Boulot","tasks":[{"title":"Finir le rapport"}]}]}
          report done: "j'ai acheté les tomates"
            → {"complete":[{"project":"Courses","task":"Acheter des tomates"}]}
          both at once: "j'ai acheté le lait, ajoute du pain"
            → {"complete":[{"project":"Groceries","task":"Buy milk"}],"projects":[{"existing_project":"Groceries","tasks":[{"title":"Buy bread"}]}]}

        For "complete", use the EXACT task/sub-task titles from EXISTING PROJECTS. Set "subtask" only \
        when reporting a single sub-task done; omit it to complete the whole task. If nothing matches, \
        do not invent a completion. Use "existing_project" only with a name that appears VERBATIM in \
        the provided list; otherwise use "new_project".

        The "due" field, when present, is ISO8601 WITH timezone offset, ONLY when the user states a \
        deadline ("friday at 3pm", "tomorrow 9am", "le 12 à midi"). Resolve relatives against the \
        context below. Never invent a deadline.

        \(nowContext())

        Keep task titles short and imperative. Detect the user's language and write ALL output in that \
        one language only — never mix languages.
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
        // {existing_project|new_project|project, tasks:[…]} (old single-project shape) is also accepted.
        var entries = (obj["projects"] as? [Any]) ?? []
        // The model may emit "projects" as a single object instead of an array.
        if entries.isEmpty, let single = obj["projects"] as? [String: Any] { entries = [single] }
        if entries.isEmpty,
           obj["tasks"] != nil || obj["items"] != nil ||
           obj["existing_project"] != nil || obj["new_project"] != nil || obj["project"] != nil {
            entries = [obj]   // treat the whole object as one project entry
        }

        var ops: [ProjectOp] = []
        for entry in entries {
            guard let e = entry as? [String: Any] else { continue }
            let tasks = parseTasks((e["tasks"] as? [Any]) ?? (e["items"] as? [Any]) ?? [])
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
            // Accept "new_project", or a bare "project"/"name" field as the new-project name.
            // When that name actually matches an existing project, append to it instead of duplicating.
            let newRaw = (e["new_project"] as? String) ?? (e["project"] as? String) ?? (e["name"] as? String)
            if let newName = newRaw?.trimmingCharacters(in: .whitespacesAndNewlines), !newName.isEmpty {
                if let match = projects.first(where: { $0.name.caseInsensitiveCompare(newName) == .orderedSame }) {
                    ops.append(ProjectOp(existingProjectID: match.id, newProjectName: nil, tasks: tasks))
                } else {
                    ops.append(ProjectOp(existingProjectID: nil, newProjectName: newName, tasks: tasks))
                }
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
    /// A plain HStack with .fixedSize() so it takes only the width it needs (no greedy ScrollView
    /// that would blow up the row width and clip the title). The title keeps layout priority.
    private var tagsRow: some View {
        HStack(spacing: 6) {
            ForEach(project.tags, id: \.self) { tag in
                HStack(spacing: 5) {
                    Text(tag).font(.caption).lineLimit(1)
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
        .fixedSize()
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
                        .lineLimit(1).fixedSize()
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
        // Drive the calendar + time editor off a single non-optional working date so
        // the popover always has something to render; commit it back to `deadline`.
        let working = Binding<Date>(
            get: { deadline ?? defaultPickerDate() },
            set: { deadline = $0 }
        )
        return VStack(alignment: .leading, spacing: 16) {
            Text("Deadline").font(.headline)

            // Quick presets
            PresetChipRows(items: presets()) { title, date in
                ChipButton(title: title, isClear: date == nil) {
                    deadline = date
                    if date == nil { show = false }
                }
            }

            // Custom month calendar — day selection.
            CalendarMonth(selection: working)

            // Custom hour + minute selector — exact time.
            TimeSelector(selection: working)

            HStack {
                Button("Clear") { deadline = nil; show = false }
                    .disabled(deadline == nil)
                Spacer()
                Button("Done") { show = false }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .frame(width: 312)
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

// MARK: - Custom month calendar (modern, on-brand — replaces stock .graphical)

/// A clean custom month grid: month/year header with prev/next chevrons, a 7-column
/// day grid, today subtly ringed, the selected day a filled accent pill, muted
/// out-of-month and past days. Editing day preserves the time-of-day in `selection`.
private struct CalendarMonth: View {
    @Binding var selection: Date

    /// The month currently shown in the grid (may differ from the selected day
    /// once the user pages with the chevrons).
    @State private var visibleMonth: Date = Date()

    private let cal = Calendar.current

    var body: some View {
        VStack(spacing: 10) {
            header
            weekdayRow
            grid
        }
        .cleanCard(padding: 12)
        .onAppear { visibleMonth = cal.startOfDay(for: selection) }
        // When the bound selection jumps to another month (a preset chip, or any
        // new deadline), page the grid to show it. Manual chevron paging only
        // moves `visibleMonth`, never `selection`, so it stays unaffected.
        .onChange(of: selection) { _, newValue in
            if !cal.isDate(newValue, equalTo: visibleMonth, toGranularity: .month) {
                withAnimation(.easeInOut(duration: 0.16)) {
                    visibleMonth = cal.startOfDay(for: newValue)
                }
            }
        }
    }

    // Month/year + paging chevrons.
    private var header: some View {
        HStack {
            Text(monthTitle(visibleMonth))
                .font(.subheadline.weight(.semibold))
            Spacer()
            HStack(spacing: 2) {
                chevron("chevron.left") { page(-1) }
                chevron("chevron.right") { page(1) }
            }
        }
    }

    private func chevron(_ name: String, _ action: @escaping () -> Void) -> some View {
        Button(action: { withAnimation(.easeInOut(duration: 0.16)) { action() } }) {
            Image(systemName: name)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 26, height: 26)
                .background(.softFill, in: Circle())
        }
        .buttonStyle(.plain)
    }

    // Localised single-letter weekday headers, ordered by the locale's first weekday.
    private var weekdayRow: some View {
        HStack(spacing: 0) {
            ForEach(orderedWeekdaySymbols(), id: \.self) { sym in
                Text(sym)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // The 6×7 day grid.
    private var grid: some View {
        let cells = monthCells()
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
            ForEach(Array(cells.enumerated()), id: \.offset) { _, day in
                if let day {
                    DayCell(
                        date: day,
                        isSelected: cal.isDate(day, inSameDayAs: selection),
                        isToday: cal.isDateInToday(day),
                        isPast: day < cal.startOfDay(for: Date()),
                        inMonth: cal.isDate(day, equalTo: visibleMonth, toGranularity: .month)
                    ) { pick(day) }
                } else {
                    Color.clear.frame(height: 30)
                }
            }
        }
    }

    // MARK: helpers

    private func monthTitle(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale.current
        f.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return f.string(from: d)
    }

    private func orderedWeekdaySymbols() -> [String] {
        let symbols = cal.veryShortStandaloneWeekdaySymbols // Sun-first
        let first = cal.firstWeekday - 1 // 0-based
        return Array(symbols[first...] + symbols[..<first])
    }

    private func page(_ delta: Int) {
        if let m = cal.date(byAdding: .month, value: delta, to: visibleMonth) {
            visibleMonth = m
        }
    }

    /// Set the day while preserving the currently-selected hour/minute.
    private func pick(_ day: Date) {
        let t = cal.dateComponents([.hour, .minute], from: selection)
        if let merged = cal.date(bySettingHour: t.hour ?? 9, minute: t.minute ?? 0, second: 0, of: day) {
            selection = merged
        }
    }

    /// All cells for the visible month, padded with nils so the 1st lands under its weekday.
    private func monthCells() -> [Date?] {
        guard let range = cal.range(of: .day, in: .month, for: visibleMonth),
              let firstOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: visibleMonth))
        else { return [] }
        let leading = (cal.component(.weekday, from: firstOfMonth) - cal.firstWeekday + 7) % 7
        var cells: [Date?] = Array(repeating: nil, count: leading)
        for d in range {
            cells.append(cal.date(byAdding: .day, value: d - 1, to: firstOfMonth))
        }
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }
}

/// One day in the calendar grid.
private struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isPast: Bool
    let inMonth: Bool
    let action: () -> Void

    private var dayNumber: String { "\(Calendar.current.component(.day, from: date))" }

    var body: some View {
        Button(action: action) {
            Text(dayNumber)
                .font(.callout.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity)
                .frame(height: 30)
                .background(background)
                .overlay {
                    if isToday && !isSelected {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color.accentColor.opacity(0.55), lineWidth: 1.2)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private var foreground: AnyShapeStyle {
        if isSelected { return AnyShapeStyle(.white) }
        if !inMonth { return AnyShapeStyle(.quaternary) }
        if isPast { return AnyShapeStyle(.tertiary) }
        return AnyShapeStyle(.primary)
    }

    @ViewBuilder private var background: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.accentColor)
        } else {
            Color.clear
        }
    }
}

// MARK: - Custom time selector (hour + minute, modern — replaces stock stepper)

/// A compact, legible time control: quick time chips plus fine ± adjustment on a
/// big, readable HH:mm readout. Edits hour/minute while preserving the day.
private struct TimeSelector: View {
    @Binding var selection: Date

    private let cal = Calendar.current

    /// Whether the locale uses a 12-hour clock (so we show AM/PM).
    private var is12h: Bool {
        let fmt = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: Locale.current) ?? ""
        return fmt.contains("a")
    }

    private var hour: Int { cal.component(.hour, from: selection) }
    private var minute: Int { cal.component(.minute, from: selection) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "clock").font(.system(size: 11)).foregroundStyle(.secondary)
                Text("Time").font(.subheadline.weight(.semibold))
                Spacer()
                Text(readout)
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }

            // Fine adjustment: hour and minute steppers.
            HStack(spacing: 8) {
                stepper(label: "Hour", onMinus: { add(hours: -1) }, onPlus: { add(hours: 1) })
                stepper(label: "Min", onMinus: { add(minutes: -5) }, onPlus: { add(minutes: 5) })
            }

            // Quick time chips.
            HStack(spacing: 8) {
                ForEach([(9, 0), (12, 0), (18, 0), (21, 0)], id: \.0) { h, m in
                    timeChip(h, m)
                }
            }
        }
        .cleanCard(padding: 12)
    }

    private var readout: String {
        let f = DateFormatter()
        f.locale = Locale.current
        f.setLocalizedDateFormatFromTemplate(is12h ? "h:mm a" : "HH:mm")
        return f.string(from: selection)
    }

    private func stepper(label: String, onMinus: @escaping () -> Void, onPlus: @escaping () -> Void) -> some View {
        HStack(spacing: 0) {
            stepButton("minus", onMinus)
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
            stepButton("plus", onPlus)
        }
        .padding(.vertical, 2)
        .background(.softFill, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    private func stepButton(_ name: String, _ action: @escaping () -> Void) -> some View {
        Button(action: { withAnimation(.easeInOut(duration: 0.12)) { action() } }) {
            Image(systemName: name)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 30, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func timeChip(_ h: Int, _ m: Int) -> some View {
        let active = hour == h && minute == m
        let f = DateFormatter()
        f.locale = Locale.current
        f.setLocalizedDateFormatFromTemplate(is12h ? "h a" : "HH:mm")
        let sample = cal.date(bySettingHour: h, minute: m, second: 0, of: selection) ?? selection
        return Button {
            withAnimation(.easeInOut(duration: 0.12)) { set(hour: h, minute: m) }
        } label: {
            Text(f.string(from: sample))
                .font(.caption.weight(.medium))
                .foregroundStyle(active ? AnyShapeStyle(.white) : AnyShapeStyle(.secondary))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(active ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.softFill), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: mutation (always preserves the day)

    private func add(hours: Int) {
        if let d = cal.date(byAdding: .hour, value: hours, to: selection) { selection = d }
    }
    private func add(minutes: Int) {
        if let d = cal.date(byAdding: .minute, value: minutes, to: selection) { selection = d }
    }
    private func set(hour: Int, minute: Int) {
        if let d = cal.date(bySettingHour: hour, minute: minute, second: 0, of: selection) { selection = d }
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
