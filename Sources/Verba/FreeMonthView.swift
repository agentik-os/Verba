import SwiftUI
import AppKit

struct FreeMonthView: View {
    @ObservedObject private var settings = Settings.shared
    @State private var copied = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Free Month").font(.system(size: 17, weight: .bold))
                    Text("Give a month, get a month. Share Verba and earn free Pro, no limit.")
                        .font(.callout).foregroundStyle(.secondary)
                }

                // Share link
                VStack(alignment: .leading, spacing: 10) {
                    Text("Your referral link").font(.subheadline.weight(.semibold))
                    HStack {
                        Text(settings.referralLink).font(.system(.callout, design: .monospaced)).lineLimit(1).truncationMode(.middle)
                        Spacer()
                        Button {
                            let pb = NSPasteboard.general; pb.clearContents(); pb.setString(settings.referralLink, forType: .string)
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.55)) { copied = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                                withAnimation(.easeOut(duration: 0.2)) { copied = false }
                            }
                        } label: {
                            Label(copied ? "Copied" : "Copy link", systemImage: copied ? "checkmark" : "doc.on.doc")
                        }
                        .glassProminentButton().tint(.primary)
                    }
                    .padding(12).frame(maxWidth: .infinity)
                    .background(.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    HStack {
                        Button { share() } label: { Label("Share…", systemImage: "square.and.arrow.up") }
                            .glassButton()
                        Spacer()
                    }
                }
                .padding(18).frame(maxWidth: .infinity, alignment: .leading)
                .glass(in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .softElevation()   // the primary action card sits forward; the steps recede

                // How it works
                VStack(alignment: .leading, spacing: 12) {
                    Text("How it works").font(.subheadline.weight(.semibold))
                    step("1", "Share your link", "Send your personal link to friends and colleagues.")
                    step("2", "They subscribe to Pro", "They sign up through your link and start a paid Verba Pro plan.")
                    step("3", "They actually use it", "Once they've dictated at least 15,000 words, the referral is validated.")
                    step("4", "You get a free month", "One free month of Pro per validated friend. Unlimited, three friends = three months.")
                }
                .padding(18).frame(maxWidth: .infinity, alignment: .leading)
                .background(.softFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                Text("Conditions: the invited person must be a paying subscriber (not just signed up) and have dictated 15,000+ words. Self-referrals don't count.")
                    .font(.caption).foregroundStyle(.tertiary).fixedSize(horizontal: false, vertical: true)
            }
            .padding(28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func share() {
        let picker = NSSharingServicePicker(items: [URL(string: settings.referralLink) ?? settings.referralLink as Any])
        if let win = NSApp.keyWindow, let view = win.contentView {
            picker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
        }
    }

    private func step(_ n: String, _ t: String, _ d: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(n).font(.headline).frame(width: 28, height: 28)
                .background(Circle().fill(Color.primary.opacity(0.1)))
            VStack(alignment: .leading, spacing: 2) {
                Text(t).font(.callout.weight(.medium))
                Text(d).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}
