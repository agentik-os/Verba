import SwiftUI

final class WishlistModel: ObservableObject {
    @Published var items: [WishItem] = []
    @Published var loading = true
    func load() { loading = true; Wishlist.list { [weak self] in self?.items = $0; self?.loading = false } }
}

struct WishlistView: View {
    @StateObject private var model = WishlistModel()
    @State private var draft = ""
    private var myUID: String { Wishlist.myUID }

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
                    .buttonStyle(.borderedProminent).tint(.primary)
                    .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 28).padding(.bottom, 12)

            if model.loading {
                ProgressView().frame(maxWidth: .infinity).padding(.top, 30)
            } else if model.items.isEmpty {
                EmptyState(icon: "lightbulb", title: "No suggestions yet",
                           message: "Tell us what Verba should do next. Post a feature idea, others can upvote it, and the most-wanted ones get built. Be the first to suggest one above.")
            }

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(model.items) { item in row(item) }
                }
                .padding(.horizontal, 28).padding(.bottom, 18)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { model.load() }
    }

    private func submit() {
        let t = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        draft = ""
        Wishlist.add(t) { model.load() }
    }

    private func row(_ item: WishItem) -> some View {
        let voted = item.voters.contains(myUID)
        return HStack(spacing: 14) {
            Button { Wishlist.upvote(item.id) { model.load() } } label: {
                VStack(spacing: 1) {
                    Image(systemName: voted ? "arrowtriangle.up.fill" : "arrowtriangle.up")
                    Text("\(Int(item.votes))").font(.caption.weight(.semibold))
                }
                .frame(width: 46)
                .foregroundStyle(voted ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
            }
            .buttonStyle(.plain)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(voted ? Color.primary.opacity(0.1) : Color.primary.opacity(0.04)))

            VStack(alignment: .leading, spacing: 3) {
                Text(item.text).fixedSize(horizontal: false, vertical: true)
                Text("by \(item.author)").font(.caption2).foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.primary.opacity(0.04)))
    }
}
