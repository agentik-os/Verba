import SwiftUI

struct FeedbackView: View {
    @State private var draft = ""
    @State private var submitting = false
    @State private var sent = false
    @State private var error: String?

    private var canSubmit: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !submitting
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Feedback").font(.system(size: 28, weight: .bold))
                Spacer()
            }
            .padding(.horizontal, 28).padding(.top, 28).padding(.bottom, 2)

            Text("Tell us what's working, what isn't, or anything on your mind. For specific feature ideas, use the Wishlist so others can upvote them.")
                .font(.callout).foregroundStyle(.secondary)
                .padding(.horizontal, 28).padding(.bottom, 16)

            if sent {
                EmptyState(icon: "checkmark.circle",
                           title: "Thanks for the feedback",
                           message: "We read every message. Want to send another? Just start typing below.")
            }

            VStack(alignment: .leading, spacing: 10) {
                TextEditor(text: $draft)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .frame(minHeight: 160)
                    .background(.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(alignment: .topLeading) {
                        if draft.isEmpty {
                            Text("Write your feedback…")
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 15).padding(.vertical, 18)
                                .allowsHitTesting(false)
                        }
                    }
                    .onChange(of: draft) { _, _ in
                        if sent { sent = false }
                        if error != nil { error = nil }
                    }

                if let error {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.callout).foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack {
                    Spacer()
                    Button(action: submit) {
                        if submitting {
                            ProgressView().controlSize(.small)
                        } else {
                            Text("Send feedback")
                        }
                    }
                    .buttonStyle(.borderedProminent).tint(.primary)
                    .disabled(!canSubmit)
                }
            }
            .padding(.horizontal, 28).padding(.bottom, 18)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func submit() {
        let t = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        submitting = true
        error = nil
        sent = false
        Feedback.submit(t) { err in
            submitting = false
            if let err {
                error = err
            } else {
                sent = true
                draft = ""
            }
        }
    }
}
