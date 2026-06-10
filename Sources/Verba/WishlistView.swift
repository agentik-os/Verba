import SwiftUI

final class WishlistModel: ObservableObject {
    @Published var items: [WishItem] = []
    @Published var loading = true
    func load() { loading = true; Wishlist.list { [weak self] in self?.items = $0; self?.loading = false } }
}

private enum WishFilter: String, CaseIterable, Identifiable {
    case all = "All", shipped = "Shipped"
    var id: String { rawValue }
    var icon: String {
        switch self { case .all: "lightbulb"; case .shipped: "checkmark.seal" }
    }
}

struct WishlistView: View {
    @StateObject private var model = WishlistModel()
    @State private var draft = ""
    @State private var expanded: Set<String> = []
    @State private var commentDrafts: [String: String] = [:]
    @State private var posting: Set<String> = []
    @State private var filter: WishFilter = .all

    // Pure presentation filter over the loaded items — no store calls.
    private var visibleItems: [WishItem] {
        filter == .all ? model.items : model.items.filter { $0.shipped }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Wishlist").font(.system(size: 28, weight: .bold))
                Spacer()
                Button { model.load() } label: { Image(systemName: "arrow.clockwise") }.buttonStyle(.borderless).help("Refresh")
            }
            .padding(.horizontal, 28).padding(.top, 28).padding(.bottom, 2)
            Text("Suggest a feature and upvote the ones you want most. We build what rises to the top.")
                .font(.callout).foregroundStyle(.secondary).padding(.horizontal, 28).padding(.bottom, 12)

            HStack(spacing: 8) {
                TextField("Suggest a feature…", text: $draft)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12).padding(.vertical, 9)
                    .background(.softFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .onSubmit(submit)
                Button("Add", action: submit)
                    .glassProminentButton().tint(.primary)
                    .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 28).padding(.bottom, 12)

            filterChips
                .padding(.horizontal, 28).padding(.bottom, 12)

            if model.loading {
                ProgressView().frame(maxWidth: .infinity).padding(.top, 30)
            } else if model.items.isEmpty {
                EmptyState(icon: "lightbulb", title: "No suggestions yet",
                           message: "Tell us what Verba should do next. Post a feature idea, others can upvote it, and the most-wanted ones get built. Be the first to suggest one above.")
            } else if visibleItems.isEmpty {
                Text("Nothing shipped yet — the most upvoted ideas get built first.")
                    .font(.callout).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity).padding(.top, 30)
            }

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(visibleItems) { item in row(item) }
                }
                .padding(.horizontal, 28).padding(.bottom, 18)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { model.load() }
    }

    // Capsule tag chips (exemplar grammar) — client-side All / Shipped switch.
    private var filterChips: some View {
        HStack(spacing: 8) {
            ForEach(WishFilter.allCases) { f in
                let selected = filter == f
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { filter = f }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: f.icon).font(.system(size: 10, weight: .semibold))
                        Text(f.rawValue).font(.system(size: 12, weight: selected ? .semibold : .medium))
                    }
                    .padding(.horizontal, 12).padding(.vertical, 6.5)
                    .foregroundStyle(selected ? AnyShapeStyle(Color.primary) : AnyShapeStyle(.primary.opacity(0.75)))
                    .background(
                        Capsule(style: .continuous)
                            .fill(selected ? AnyShapeStyle(Color.primary.opacity(0.10)) : AnyShapeStyle(Color.primary.opacity(0.055)))
                    )
                    .overlay(Capsule(style: .continuous).strokeBorder(selected ? Color.primary.opacity(0.18) : Color.primary.opacity(0.09), lineWidth: 1))
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    private func submit() {
        let t = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        draft = ""
        Wishlist.add(t) { model.load() }
    }

    private func row(_ item: WishItem) -> some View {
        let voted = item.mine   // HANDOFF-5: server `mine` flag + local vote cache, no voters list
        let shipped = item.shipped
        let isOpen = expanded.contains(item.id)
        return VStack(alignment: .leading, spacing: 0) {
            // Header — upvote + text + a discreet comment count. Tapping anywhere here toggles.
            HStack(spacing: 14) {
                Button { if !shipped { Wishlist.upvote(item.id) { model.load() } } } label: {
                    VStack(spacing: 1) {
                        Image(systemName: shipped ? "checkmark.circle.fill"
                              : (voted ? "arrowtriangle.up.fill" : "arrowtriangle.up"))
                        Text("\(Int(item.votes))").font(.caption.weight(.semibold)).monospacedDigit()
                    }
                    .frame(width: 46)
                    .foregroundStyle(shipped ? AnyShapeStyle(.green)
                                     : (voted ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary)))
                }
                .buttonStyle(.plain)
                .disabled(shipped)
                .help(shipped ? "Shipped — already built" : "Upvote")
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(voted && !shipped ? Color.primary.opacity(0.1) : Color.primary.opacity(0.04)))

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.text).fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 6) {
                        Text("by \(item.author)").font(.caption2).foregroundStyle(.tertiary)
                        if shipped {
                            Text("SHIPPED")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.green)
                                .padding(.horizontal, 6).padding(.vertical, 1)
                                .background(Capsule().fill(Color.green.opacity(0.15)))
                        }
                    }
                }
                Spacer(minLength: 0)
                commentBadge(item, open: isOpen)
            }
            .contentShape(Rectangle())
            .onTapGesture { toggle(item.id) }

            if isOpen {
                commentsSection(item)
                    .padding(.top, 10)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.primary.opacity(0.04)))
    }

    // Discreet speech-bubble + count; the chevron hints the card expands.
    private func commentBadge(_ item: WishItem, open: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "bubble.left").font(.caption)
            Text("\(item.commentCount)").font(.caption.weight(.medium)).monospacedDigit()
            Image(systemName: "chevron.down")
                .font(.system(size: 9, weight: .semibold))
                .rotationEffect(.degrees(open ? 180 : 0))
        }
        .foregroundStyle(.secondary)
        .help(open ? "Hide comments" : "Show comments")
    }

    private func toggle(_ id: String) {
        withAnimation(.easeInOut(duration: 0.18)) {
            if expanded.contains(id) { expanded.remove(id) } else { expanded.insert(id) }
        }
    }

    @ViewBuilder
    private func commentsSection(_ item: WishItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider().opacity(0.5)
            if item.comments.isEmpty {
                Text("No comments yet. Start the conversation.")
                    .font(.caption).foregroundStyle(.tertiary)
            } else {
                ForEach(item.comments) { c in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(c.author).font(.caption.weight(.semibold))
                            Text(relativeTime(c)).font(.caption2).foregroundStyle(.tertiary)
                        }
                        Text(c.text).font(.callout).fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.primary.opacity(0.04)))
                }
            }

            HStack(spacing: 8) {
                TextField("Add a comment…", text: commentBinding(item.id))
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 10).padding(.vertical, 7)
                    .background(.softFill, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                    .onSubmit { postComment(item.id) }
                if posting.contains(item.id) {
                    ProgressView().controlSize(.small)
                }
                Button("Post") { postComment(item.id) }
                    .glassButton()
                    .disabled(
                        posting.contains(item.id) ||
                        (commentDrafts[item.id]?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
                    )
            }
        }
    }

    private func commentBinding(_ id: String) -> Binding<String> {
        Binding(get: { commentDrafts[id] ?? "" }, set: { commentDrafts[id] = $0 })
    }

    private func relativeTime(_ c: WishComment) -> String {
        guard let d = c.created else { return "" }
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f.localizedString(for: d, relativeTo: Date())
    }

    private func postComment(_ id: String) {
        let t = (commentDrafts[id] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, !posting.contains(id) else { return }
        posting.insert(id)
        Wishlist.comment(id, t) {
            commentDrafts[id] = ""
            posting.remove(id)
            model.load()
        }
    }
}
