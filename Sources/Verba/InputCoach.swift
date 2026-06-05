import Foundation
import Combine

/// Tracks which keyboard actions the user has performed, so the onboarding can detect
/// "you did it" live and guide them through single tap / hold / double-tap / Control.
final class InputCoach: ObservableObject {
    static let shared = InputCoach()
    enum Action { case singleFn, holdFn, doubleFn, control }

    @Published var singleFn = false
    @Published var holdFn = false
    @Published var doubleFn = false
    @Published var control = false

    func note(_ a: Action) {
        switch a {
        case .singleFn: singleFn = true
        case .holdFn:   holdFn = true
        case .doubleFn: doubleFn = true
        case .control:  control = true
        }
    }
    func reset() { singleFn = false; holdFn = false; doubleFn = false; control = false }
}
