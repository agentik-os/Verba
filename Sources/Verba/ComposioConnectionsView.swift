import SwiftUI
import AppKit

// MARK: - Connected apps (Composio) view
//
// The "Connect your apps" surface for Action mode: a grid of connectable third-party apps
// (Gmail, Slack, Notion, …) each with a category chip and a Connect button. Connecting opens
// the OAuth flow in the browser via ComposioStore.shared.connect(slug); the card shows
// "Connecting…" until the next ComposioStore refresh reports the connection ACTIVE.
//
// Catalog note: this static list mirrors the site's public catalog
// (website/app/api/composio/apps/route.ts) — slugs/names/categories must stay in sync.

/// One connectable app in the catalog (slug = Composio toolkit slug).
struct ComposioCatalogApp: Identifiable {
    let slug: String
    let name: String
    let cat: String
    var auth: String = "oauth"   // oauth | api_key | bearer | basic | none
    var id: String { slug }
}

/// Full-page Connected Apps, surfaced in the sidebar under Library (moved out of Settings — it's a
/// first-class feature). Wraps the inline grid with the page title + the same intro it had in Settings.
struct ConnectedAppsPage: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(L("Connected apps")).font(.system(size: 22, weight: .bold))
                Text(L("Connect your favorite apps, then let JARVIS act on them by voice in Action mode — send an email, post to Slack, create a calendar event, add a Notion page, and hundreds more. Your connection keys stay on Verba's servers, never on your Mac."))
                    .font(.callout).foregroundStyle(.secondary)
                ComposioConnectionsView(embedded: true)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct ComposioConnectionsView: View {
    var embedded = false   // true → render inline (no window chrome) inside Settings ▸ Action
    @ObservedObject private var store = ComposioStore.shared
    @ObservedObject private var logos = LogoLoader.shared
    @Environment(\.dismiss) private var dismiss

    @State private var categoryFilter: String? = nil   // nil = All
    @State private var searchQuery = ""
    @State private var actionsApp: ComposioCatalogApp? = nil   // tapped app → its actions sheet
    @State private var credentialApp: ComposioCatalogApp? = nil   // credential-auth app → connect modal

    private let cols = [GridItem(.adaptive(minimum: 190), spacing: 10)]

    /// The live catalog from the server (`/apps`, ~600 apps); the bundled list is only a fallback
    /// shown before the fetch lands or when offline.
    private var allApps: [ComposioCatalogApp] {
        store.apps.isEmpty
            ? Self.catalog
            : store.apps.map { ComposioCatalogApp(slug: $0.slug, name: $0.name, cat: $0.cat, auth: $0.auth) }
    }

    /// The catalog filtered by the selected category and the search query.
    private var filtered: [ComposioCatalogApp] {
        var list = allApps
        if let f = categoryFilter { list = list.filter { $0.cat == f } }
        let q = searchQuery.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty { list = list.filter { $0.name.lowercased().contains(q) || $0.slug.lowercased().contains(q) } }
        return list
    }
    /// Categories present in the catalog, in display order (for the filter bar).
    private var presentCategories: [String] {
        var seen = Set<String>(); var out: [String] = []
        for a in allApps where !seen.contains(a.cat) { seen.insert(a.cat); out.append(a.cat) }
        return out
    }

    /// A search box for finding an app by name among the hundreds available.
    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass").font(.system(size: 11)).foregroundStyle(.secondary)
            TextField(L("Search apps"), text: $searchQuery).textFieldStyle(.plain).font(.system(size: 12))
            if !searchQuery.isEmpty {
                Button { searchQuery = "" } label: {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 11)).foregroundStyle(.tertiary)
                }.buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Color.primary.opacity(0.05), in: Capsule())
    }

    /// "N apps you can connect · M connected" — flexes the breadth of the catalog.
    private var countLabel: some View {
        let total = allApps.count
        let connected = store.connections.values.filter { $0.uppercased() == "ACTIVE" }.count
        return HStack(spacing: 5) {
            Text(String(format: L("%d apps you can connect"), total))
                .font(.system(size: 11)).foregroundStyle(.secondary)
            if connected > 0 {
                Text("·").foregroundStyle(.secondary)
                Text(String(format: L("%d connected"), connected))
                    .font(.system(size: 11, weight: .semibold)).foregroundStyle(.green)
            }
        }
    }

    /// A horizontal category filter bar (All + each category chip).
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                filterPill(L("All"), active: categoryFilter == nil) { categoryFilter = nil }
                ForEach(presentCategories, id: \.self) { cat in
                    let (label, _) = Self.categories[cat] ?? (cat.capitalized, .gray)
                    filterPill(L(label), active: categoryFilter == cat) { categoryFilter = cat }
                }
            }
        }
    }
    private func filterPill(_ title: String, active: Bool, _ tap: @escaping () -> Void) -> some View {
        Button(action: tap) {
            Text(title)
                .font(.system(size: 11.5, weight: active ? .semibold : .medium))
                .padding(.horizontal, 12).padding(.vertical, 5)
                .foregroundStyle(active ? AnyShapeStyle(Color.white) : AnyShapeStyle(Color.primary.opacity(0.65)))
                .background(active ? AnyShapeStyle(VerbaAppearance.shared.tint)
                                  : AnyShapeStyle(Color.primary.opacity(0.05)), in: Capsule())
        }.buttonStyle(.plain)
    }

    var body: some View {
        Group {
            if embedded {
                // Inline in the settings page (the page scrolls): search + filter bar + grid.
                VStack(alignment: .leading, spacing: 10) {
                    searchField
                    filterBar
                    countLabel
                    LazyVGrid(columns: cols, spacing: 10) {
                        ForEach(filtered) { app in card(app) }
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    searchField.padding(.horizontal, 24).padding(.bottom, 6)
                    filterBar.padding(.horizontal, 24).padding(.bottom, 6)
                    ScrollView {
                        LazyVGrid(columns: cols, spacing: 12) {
                            ForEach(filtered) { app in card(app) }
                        }
                        .padding(.horizontal, 24).padding(.vertical, 18)
                    }
                }
                .frame(minWidth: 620, idealWidth: 720, minHeight: 460, idealHeight: 560)
                .background(VisualEffectView().ignoresSafeArea())
            }
        }
        .onAppear { store.refresh() }
        .sheet(item: $actionsApp) { app in AppActionsView(app: app) }
        .sheet(item: $credentialApp) { app in CredentialConnectView(app: app) }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Image(systemName: "app.connected.to.app.below.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(VerbaAppearance.shared.tint)
                Text(L("Connect your apps")).font(.system(size: 17, weight: .bold))
                Spacer()
                Button {
                    store.refresh()
                } label: {
                    Label(L("Refresh"), systemImage: "arrow.clockwise")
                }
                .glassButton()
                .help(L("Refresh connection status"))
                Button(L("Done")) { dismiss() }
                    .glassProminentButton()
                    .keyboardShortcut(.defaultAction)
            }
            Text(L("Connect your apps so Action mode can act on them by voice."))
                .font(.callout).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 24).padding(.top, 22).padding(.bottom, 12)
    }

    // MARK: App card

    @ViewBuilder private func card(_ app: ComposioCatalogApp) -> some View {
        let isActive = store.isConnected(app.slug)   // connections is keyed lowercased
        let isConnecting = !isActive && store.isConnecting(app.slug)
        VStack(alignment: .leading, spacing: 9) {
            // Logo + name, category tag UNDER the name (full, never cut). Tap to see the app's
            // actions + example phrases for JARVIS.
            HStack(alignment: .center, spacing: 9) {
                logoView(app)
                VStack(alignment: .leading, spacing: 3) {
                    Text(app.name)
                        .font(.system(size: 12.5, weight: .medium))   // lighter title
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    chip(app.cat)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold)).foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
            .onTapGesture { actionsApp = app }
            .help(L("See what you can ask JARVIS to do with \(app.name)"))
            Spacer(minLength: 2)
            actionRow(app, isActive: isActive, isConnecting: isConnecting)
        }
        .padding(13)
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
        .background(isActive ? AnyShapeStyle(VerbaAppearance.shared.tint.opacity(0.06))
                             : AnyShapeStyle(Color.primary.opacity(0.025)),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isActive ? VerbaAppearance.shared.tint.opacity(0.40)
                                 : Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    /// Bottom action row: Connected + Disconnect, Connecting…, or a subtle Connect pill.
    @ViewBuilder private func actionRow(_ app: ComposioCatalogApp, isActive: Bool, isConnecting: Bool) -> some View {
        if isActive {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 11)).foregroundStyle(.green)
                Text(L("Connected")).font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
                    .lineLimit(1).minimumScaleFactor(0.7).layoutPriority(0)
                Spacer(minLength: 4)
                Button { store.disconnect(toolkitSlug: app.slug) } label: {
                    Text(L("Disconnect"))
                        .font(.system(size: 10.5, weight: .medium))
                        .lineLimit(1).fixedSize()        // never wrap to "Disconn / ect"
                        .padding(.horizontal, 9).padding(.vertical, 3.5)
                        .foregroundStyle(.secondary)
                        .overlay(Capsule().stroke(Color.primary.opacity(0.14), lineWidth: 1))
                }.buttonStyle(.plain).layoutPriority(1)
            }
        } else if isConnecting {
            HStack(spacing: 6) {
                ProgressView().controlSize(.small).scaleEffect(0.75)
                Text(L("Connecting…")).font(.system(size: 11)).foregroundStyle(.secondary)
                    .lineLimit(1).layoutPriority(0)
                Spacer(minLength: 4)
                Button { store.cancelConnect(app.slug) } label: {
                    Text(L("Cancel"))
                        .font(.system(size: 10.5, weight: .medium))
                        .lineLimit(1).fixedSize()
                        .padding(.horizontal, 9).padding(.vertical, 3.5)
                        .foregroundStyle(.secondary)
                        .overlay(Capsule().stroke(Color.primary.opacity(0.14), lineWidth: 1))
                }.buttonStyle(.plain).layoutPriority(1)
            }
        } else {
            HStack {
                Spacer(minLength: 0)
                Button {
                    if app.auth == "oauth" || app.auth == "none" {
                        store.connect(toolkitSlug: app.slug, auth: app.auth)
                    } else {
                        credentialApp = app   // api_key / bearer / basic → ask for the credentials
                    }
                } label: {
                    Text(L("Connect"))
                        .font(.system(size: 11.5, weight: .semibold))
                        .lineLimit(1).fixedSize()
                        .padding(.horizontal, 14).padding(.vertical, 5)
                        .background(VerbaAppearance.shared.tint.opacity(0.14), in: Capsule())
                        .foregroundStyle(VerbaAppearance.shared.tint)
                }.buttonStyle(.plain)
            }
        }
    }

    /// The app's logo: a rasterized brand SVG (LogoLoader) or a tinted monogram while it loads /
    /// if it never arrives. SwiftUI can't render a vector-only NSImage with `.resizable()`, so
    /// LogoLoader bakes each SVG into a bitmap first.
    private func logoView(_ app: ComposioCatalogApp) -> some View {
        let (_, tint) = Self.categories[app.cat] ?? ("", .gray)
        return Group {
            if let img = logos.image(for: app.slug) {
                Image(nsImage: img).resizable().scaledToFit().padding(2)
            } else {
                Text(String(app.name.prefix(1)))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(tint)
            }
        }
        .frame(width: 28, height: 28)
        .background(logos.image(for: app.slug) == nil ? AnyShapeStyle(tint.opacity(0.14)) : AnyShapeStyle(Color.clear),
                    in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        .onAppear { logos.load(app.slug) }
    }

    /// Small colored category chip.
    private func chip(_ cat: String) -> some View {
        let (label, tint) = Self.categories[cat] ?? (cat.capitalized, .gray)
        return Text(L(label))
            .font(.system(size: 9.5, weight: .semibold))
            .lineLimit(1).fixedSize()        // never truncate the category tag
            .padding(.horizontal, 7).padding(.vertical, 2.5)
            .background(tint.opacity(0.14), in: Capsule())
            .foregroundStyle(tint)
    }

    // MARK: Category display names + chip colors

    /// cat key → (localizable display label, chip tint).
    private static let categories: [String: (String, Color)] = [
        "email":        ("Email", .blue),
        "developer":    ("Developer", .purple),
        "scheduling":   ("Scheduling", .orange),
        "notes":        ("Notes", .yellow),
        "spreadsheets": ("Spreadsheets", .green),
        "chat":         ("Chat", .teal),
        "social":       ("Social", .pink),
        "storage":      ("Storage", .cyan),
        "documents":    ("Documents", .indigo),
        "crm":          ("CRM", .red),
        "project":      ("Project", .mint),
        "productivity": ("Productivity", .orange),
        "video":        ("Video", .red),
        "tasks":        ("Tasks", .green),
        "design":       ("Design", .purple),
        "ecommerce":    ("E-commerce", .brown),
        "maps":         ("Maps", .green),
        "signatures":   ("Signatures", .indigo),
        "payments":     ("Payments", .blue),
        "marketing":    ("Marketing", .pink),
        "analytics":    ("Analytics", .cyan),
        "meetings":     ("Meetings", .blue),
        "support":      ("Support", .teal),
        "music":        ("Music", .pink),
        "ai":           ("AI", .purple),
        "scraping":     ("Scraping", .orange),
        "database":     ("Database", .indigo),
        "news":         ("News", .red),
        "forms":        ("Forms", .teal),
        "finance":      ("Finance", .green),
        "hr":           ("HR", .pink),
        "docs":         ("Docs", .indigo),
        "cms":          ("CMS", .cyan),
        "security":     ("Security", .red),
        "education":    ("Education", .orange),
        "search":       ("Search", .blue),
        "other":        ("Other", .gray),
    ]

    // MARK: Catalog (mirror of website/app/api/composio/apps/route.ts — keep in sync)

    static let catalog: [ComposioCatalogApp] = [
        .init(slug: "GMAIL", name: "Gmail", cat: "email"),
        .init(slug: "GITHUB", name: "GitHub", cat: "developer"),
        .init(slug: "GOOGLECALENDAR", name: "Google Calendar", cat: "scheduling"),
        .init(slug: "NOTION", name: "Notion", cat: "notes"),
        .init(slug: "GOOGLESHEETS", name: "Google Sheets", cat: "spreadsheets"),
        .init(slug: "SLACK", name: "Slack", cat: "chat"),
        .init(slug: "OUTLOOK", name: "Outlook", cat: "email"),
        .init(slug: "TWITTER", name: "Twitter", cat: "social"),
        .init(slug: "GOOGLEDRIVE", name: "Google Drive", cat: "storage"),
        .init(slug: "GOOGLEDOCS", name: "Google Docs", cat: "documents"),
        .init(slug: "HUBSPOT", name: "HubSpot", cat: "crm"),
        .init(slug: "LINEAR", name: "Linear", cat: "project"),
        .init(slug: "AIRTABLE", name: "Airtable", cat: "productivity"),
        .init(slug: "JIRA", name: "Jira", cat: "project"),
        .init(slug: "YOUTUBE", name: "YouTube", cat: "video"),
        .init(slug: "GOOGLETASKS", name: "Google Tasks", cat: "tasks"),
        .init(slug: "DISCORD", name: "Discord", cat: "chat"),
        .init(slug: "FIGMA", name: "Figma", cat: "design"),
        .init(slug: "REDDIT", name: "Reddit", cat: "social"),
        .init(slug: "CAL", name: "Cal.com", cat: "scheduling"),
        .init(slug: "SENTRY", name: "Sentry", cat: "developer"),
        .init(slug: "MICROSOFT_TEAMS", name: "Microsoft Teams", cat: "chat"),
        .init(slug: "ASANA", name: "Asana", cat: "project"),
        .init(slug: "SHOPIFY", name: "Shopify", cat: "ecommerce"),
        .init(slug: "LINKEDIN", name: "LinkedIn", cat: "social"),
        .init(slug: "GOOGLE_MAPS", name: "Google Maps", cat: "maps"),
        .init(slug: "ONE_DRIVE", name: "OneDrive", cat: "storage"),
        .init(slug: "DOCUSIGN", name: "DocuSign", cat: "signatures"),
        .init(slug: "SALESFORCE", name: "Salesforce", cat: "crm"),
        .init(slug: "CALENDLY", name: "Calendly", cat: "scheduling"),
        .init(slug: "TRELLO", name: "Trello", cat: "project"),
        .init(slug: "APOLLO", name: "Apollo", cat: "crm"),
        .init(slug: "CLICKUP", name: "ClickUp", cat: "productivity"),
        .init(slug: "STRIPE", name: "Stripe", cat: "payments"),
        .init(slug: "BREVO", name: "Brevo", cat: "email"),
        .init(slug: "KLAVIYO", name: "Klaviyo", cat: "marketing"),
        .init(slug: "POSTHOG", name: "PostHog", cat: "analytics"),
        .init(slug: "SUPABASE", name: "Supabase", cat: "developer"),
        .init(slug: "BITBUCKET", name: "Bitbucket", cat: "developer"),
        .init(slug: "GITLAB", name: "GitLab", cat: "developer"),
        .init(slug: "DROPBOX", name: "Dropbox", cat: "storage"),
        .init(slug: "ZOOM", name: "Zoom", cat: "meetings"),
        .init(slug: "INTERCOM", name: "Intercom", cat: "support"),
        .init(slug: "ZENDESK", name: "Zendesk", cat: "support"),
        .init(slug: "MAILCHIMP", name: "Mailchimp", cat: "marketing"),
        .init(slug: "WHATSAPP", name: "WhatsApp", cat: "chat"),
        .init(slug: "TELEGRAM", name: "Telegram", cat: "chat"),
        .init(slug: "SPOTIFY", name: "Spotify", cat: "music"),
        .init(slug: "TODOIST", name: "Todoist", cat: "tasks"),
        .init(slug: "AHREFS", name: "Ahrefs", cat: "marketing"),
    ]
}

// MARK: - App actions sheet
//
// Tapping an app opens this: the actions JARVIS can perform with it, each with example phrases the
// user can SPEAK to trigger it. Actions + phrases come from GET /api/composio/actions?toolkit=X.

struct AppActionsView: View {
    let app: ComposioCatalogApp
    @ObservedObject private var logos = LogoLoader.shared
    @Environment(\.dismiss) private var dismiss
    @State private var actions: [ComposioAction] = []
    @State private var loading = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 11) {
                logo
                VStack(alignment: .leading, spacing: 2) {
                    Text(app.name).font(.system(size: 16, weight: .bold))
                    Text(L("What you can ask JARVIS to do")).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button(L("Done")) { dismiss() }.glassProminentButton().keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 22).padding(.vertical, 18)
            Divider()
            Group {
                if loading {
                    VStack(spacing: 10) {
                        ProgressView()
                        Text(L("Loading actions…")).font(.system(size: 12)).foregroundStyle(.secondary)
                    }.frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if actions.isEmpty {
                    Text(L("No actions available for this app yet."))
                        .font(.system(size: 13)).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(actions) { actionRow($0) }
                        }.padding(20)
                    }
                }
            }
        }
        .frame(width: 560, height: 620)
        .background(VisualEffectView().ignoresSafeArea())
        .task {
            actions = await ComposioStore.shared.actions(for: app.slug)
            loading = false
        }
    }

    private var logo: some View {
        Group {
            if let img = logos.image(for: app.slug) { Image(nsImage: img).resizable().scaledToFit().padding(2) }
            else { Image(systemName: "app.dashed").font(.system(size: 16)).foregroundStyle(.secondary) }
        }
        .frame(width: 32, height: 32)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .onAppear { logos.load(app.slug) }
    }

    @ViewBuilder private func actionRow(_ a: ComposioAction) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(a.name).font(.system(size: 13, weight: .semibold))
            if !a.description.isEmpty {
                Text(a.description).font(.system(size: 11.5)).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(a.phrases, id: \.self) { p in
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "quote.bubble.fill")
                        .font(.system(size: 9)).foregroundStyle(VerbaAppearance.shared.tint)
                        .padding(.top, 2)
                    Text("\u{201C}\(p)\u{201D}").font(.system(size: 12)).foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.025), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.primary.opacity(0.08), lineWidth: 1))
    }
}

// MARK: - Credential connect modal (API key / bearer / basic auth)
//
// For the ~830 toolkits that authenticate with an API key (not OAuth), clicking Connect opens this:
// the exact fields the toolkit needs (from /connect-fields), then it creates the connection.

struct CredentialConnectView: View {
    let app: ComposioCatalogApp
    @ObservedObject private var store = ComposioStore.shared
    @ObservedObject private var logos = LogoLoader.shared
    @Environment(\.dismiss) private var dismiss
    @State private var fields: [ComposioField] = []
    @State private var loading = true

    private var ready: Bool {
        fields.allSatisfy { !$0.required || !$0.value.trimmingCharacters(in: .whitespaces).isEmpty }
    }
    private func isSecret(_ name: String) -> Bool {
        let n = name.lowercased()
        return n.contains("key") || n.contains("token") || n.contains("secret") || n.contains("password") || n.contains("pass")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 11) {
                Group {
                    if let img = logos.image(for: app.slug) { Image(nsImage: img).resizable().scaledToFit().padding(2) }
                    else { Image(systemName: "key.fill").font(.system(size: 15)).foregroundStyle(.secondary) }
                }
                .frame(width: 30, height: 30).clipShape(RoundedRectangle(cornerRadius: 7)).onAppear { logos.load(app.slug) }
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: L("Connect %@"), app.name)).font(.system(size: 16, weight: .bold))
                    Text(L("Enter your credentials to connect")).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 20).padding(.vertical, 16)
            Divider()
            if loading {
                ProgressView().frame(maxWidth: .infinity).padding(40)
            } else if fields.isEmpty {
                Text(L("Couldn't load the connection details. Try again.")).font(.system(size: 12))
                    .foregroundStyle(.secondary).padding(24)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach($fields) { $f in
                            VStack(alignment: .leading, spacing: 3) {
                                Text(f.label + (f.required ? " *" : "")).font(.system(size: 11, weight: .medium))
                                if !f.description.isEmpty {
                                    Text(f.description).font(.system(size: 10.5)).foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Group {
                                    if isSecret(f.name) { SecureField(f.label, text: $f.value) }
                                    else { TextField(f.label, text: $f.value) }
                                }
                                .textFieldStyle(.plain).font(.system(size: 12))
                                .padding(.horizontal, 9).padding(.vertical, 7)
                                .background(.softFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Color.hairlineTint, lineWidth: 1))
                            }
                        }
                    }.padding(18)
                }
                HStack(spacing: 10) {
                    Button(L("Cancel")) { dismiss() }.glassButton()
                    Spacer()
                    Button {
                        var dict: [String: String] = [:]
                        for f in fields { dict[f.name] = f.value }
                        store.connectWithCredentials(toolkitSlug: app.slug, auth: app.auth, fields: dict)
                        dismiss()
                    } label: {
                        Text(L("Connect")).frame(maxWidth: 120)
                    }
                    .glassProminentButton().disabled(!ready).keyboardShortcut(.defaultAction)
                }
                .padding(.horizontal, 18).padding(.vertical, 14)
            }
        }
        .frame(width: 460, height: 480)
        .background(VisualEffectView().ignoresSafeArea())
        .task {
            fields = await store.connectFields(toolkitSlug: app.slug, auth: app.auth)
            loading = false
        }
    }
}

// MARK: - Logo loader (SVG → bitmap)
//
// Composio serves app logos as SVG (logos.composio.dev/api/<slug>). macOS NSImage decodes
// SVG fine, but SwiftUI's `Image(nsImage:).resizable()` renders BLANK for a vector-only
// NSImage — there's no bitmap representation to stretch. So we fetch each SVG once, force a
// fixed-size rasterization (set size → tiffRepresentation → bitmap NSImage), and cache it.
@MainActor
final class LogoLoader: ObservableObject {
    static let shared = LogoLoader()
    @Published private(set) var images: [String: NSImage] = [:]
    private var inflight: Set<String> = []

    func image(for slug: String) -> NSImage? { images[slug.lowercased()] }

    /// Loads + rasterizes the logo for `slug` once; no-op if cached or already in flight.
    func load(_ slug: String) {
        let key = slug.lowercased()
        guard images[key] == nil, !inflight.contains(key),
              let url = URL(string: "https://logos.composio.dev/api/\(key)") else { return }
        inflight.insert(key)
        Task {
            let data = try? await URLSession.shared.data(from: url).0
            await MainActor.run {
                self.inflight.remove(key)
                guard let data, let svg = NSImage(data: data), svg.isValid else { return }
                svg.size = NSSize(width: 64, height: 64)   // 2× a 32pt slot
                guard let tiff = svg.tiffRepresentation, let bitmap = NSImage(data: tiff) else { return }
                self.images[key] = bitmap
            }
        }
    }
}
