import SwiftUI

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
    var id: String { slug }
}

struct ComposioConnectionsView: View {
    var embedded = false   // true → render inline (no window chrome) inside Settings ▸ Action
    @ObservedObject private var store = ComposioStore.shared
    @Environment(\.dismiss) private var dismiss

    /// Slugs whose OAuth flow was just launched — shown as "Connecting…" until the
    /// next store refresh flips them ACTIVE (or the user retries).
    @State private var connecting: Set<String> = []
    @State private var categoryFilter: String? = nil   // nil = All

    private let cols = [GridItem(.adaptive(minimum: 150), spacing: 10)]

    /// The catalog filtered by the selected category.
    private var filtered: [ComposioCatalogApp] {
        guard let f = categoryFilter else { return Self.catalog }
        return Self.catalog.filter { $0.cat == f }
    }
    /// Categories present in the catalog, in display order (for the filter bar).
    private var presentCategories: [String] {
        var seen = Set<String>(); var out: [String] = []
        for a in Self.catalog where !seen.contains(a.cat) { seen.insert(a.cat); out.append(a.cat) }
        return out
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
            Text(title).font(.system(size: 11, weight: active ? .semibold : .regular))
                .padding(.horizontal, 11).padding(.vertical, 5)
                .background(active ? AnyShapeStyle(.primary.opacity(0.9)) : AnyShapeStyle(.softFill), in: Capsule())
                .foregroundStyle(active ? AnyShapeStyle(Color(nsColor: .windowBackgroundColor)) : AnyShapeStyle(.primary))
        }.buttonStyle(.plain)
    }

    var body: some View {
        Group {
            if embedded {
                // Inline in the settings page (the page scrolls): filter bar + grid, no window chrome.
                VStack(alignment: .leading, spacing: 12) {
                    filterBar
                    LazyVGrid(columns: cols, spacing: 10) {
                        ForEach(filtered) { app in card(app) }
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    header
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
        .onChange(of: store.connections) { _, new in
            connecting = connecting.filter { (new[$0.lowercased()] ?? "").uppercased() != "ACTIVE" }
        }
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
        let isConnecting = !isActive && connecting.contains(app.slug)
        VStack(alignment: .leading, spacing: 8) {
            // Logo + full app name (wraps, never cut).
            HStack(alignment: .top, spacing: 8) {
                logo(app.slug)
                Text(app.name)
                    .font(.system(size: 13, weight: .semibold))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            // Category tag UNDER the name, full width.
            chip(app.cat)
            Spacer(minLength: 4)
            // Action row.
            if isActive {
                HStack(spacing: 6) {
                    Label(L("Connected"), systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold)).foregroundStyle(.green)
                    Spacer(minLength: 4)
                    Button(L("Disconnect")) { store.disconnect(toolkitSlug: app.slug) }
                        .glassButton().controlSize(.small)
                }
            } else if isConnecting {
                HStack(spacing: 6) {
                    ProgressView().controlSize(.small)
                    Text(L("Connecting…")).font(.system(size: 12)).foregroundStyle(.secondary)
                }
            } else {
                Button {
                    connecting.insert(app.slug)
                    store.connect(toolkitSlug: app.slug)
                } label: {
                    Text(L("Connect")).font(.system(size: 12, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .glassButton()
                .controlSize(.small)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
        .glass(in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .glassSelection(isActive, cornerRadius: 14)
    }

    /// The app's logo from Composio's hosted logo CDN (falls back to a tinted placeholder).
    private func logo(_ slug: String) -> some View {
        AsyncImage(url: URL(string: "https://logos.composio.dev/api/\(slug.lowercased())")) { phase in
            if let img = phase.image { img.resizable().scaledToFit() }
            else { RoundedRectangle(cornerRadius: 5, style: .continuous).fill(Color.primary.opacity(0.06)) }
        }
        .frame(width: 22, height: 22)
        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
    }

    /// Small colored category chip.
    private func chip(_ cat: String) -> some View {
        let (label, tint) = Self.categories[cat] ?? (cat.capitalized, .gray)
        return Text(L(label))
            .font(.system(size: 9.5, weight: .semibold))
            .lineLimit(1).fixedSize()        // never truncate the category tag
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(tint.opacity(0.16), in: Capsule())
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
