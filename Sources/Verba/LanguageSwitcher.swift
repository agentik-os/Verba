import SwiftUI
import AppKit

/// Translate a UI string to the user's chosen interface language (resolves against the selected
/// .lproj). Returns the original string if there's no translation. Used app-wide as `L("…")`.
func L(_ key: String) -> String {
    LocaleManager.bundle.localizedString(forKey: key, value: key, table: nil)
}

// MARK: - App UI language (relaunch to apply a bundled .lproj)

/// Redirects Bundle.main string lookups to a chosen .lproj, so the UI language can be set reliably
/// for a hand-bundled SwiftPM app (where Bundle.main's automatic localization selection is flaky).
private var verbaBundleAssocKey: UInt8 = 0
final class VerbaLocalizedBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if let path = objc_getAssociatedObject(self, &verbaBundleAssocKey) as? String,
           let lb = Bundle(path: path) {
            return lb.localizedString(forKey: key, value: value, table: tableName)
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}

enum LocaleManager {
    private static let kUILang = "verba.uiLanguage"   // stored .lproj code, "" = system/English

    /// Language NAME → bundled .lproj code.
    static let lproj: [String: String] = [
        "English": "en", "French": "fr", "Spanish": "es", "German": "de", "Italian": "it",
        "Portuguese": "pt", "Dutch": "nl", "Russian": "ru", "Chinese": "zh-Hans", "Japanese": "ja",
        "Korean": "ko", "Arabic": "ar", "Hindi": "hi", "Turkish": "tr", "Polish": "pl",
    ]

    static var savedCode: String { UserDefaults.standard.string(forKey: kUILang) ?? "" }

    /// The bundle for the chosen UI language (its .lproj), or the main bundle for English/default.
    /// SwiftUI's automatic Text localization is unreliable for a hand-bundled SwiftPM app, so we
    /// resolve strings explicitly against this bundle via L(_:).
    static var bundle: Bundle {
        guard !savedCode.isEmpty,
              let p = Bundle.main.path(forResource: savedCode, ofType: "lproj"),
              let b = Bundle(path: p) else { return .main }
        return b
    }

    /// Point Bundle.main at the given .lproj code (call at launch). nil/"" → default English.
    static func applyAtLaunch() {
        object_setClass(Bundle.main, VerbaLocalizedBundle.self)
        redirect(savedCode)
    }
    private static func redirect(_ code: String) {
        let path = code.isEmpty ? nil : Bundle.main.path(forResource: code, ofType: "lproj")
        objc_setAssociatedObject(Bundle.main, &verbaBundleAssocKey, path, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    /// Persist the chosen interface language and relaunch so every window/menu rebuilds translated.
    static func applyUILanguage(_ name: String) {
        let code = name.isEmpty ? "" : (lproj[name] ?? "")
        UserDefaults.standard.set(code, forKey: kUILang)
        UserDefaults.standard.synchronize()
        let p = Process(); p.launchPath = "/usr/bin/open"; p.arguments = ["-n", Bundle.main.bundlePath]
        try? p.run()
        NSApp.terminate(nil)
    }

    /// Offer to switch the interface language (with a restart) after the user picks an output language.
    static func offerUISwitch(to name: String) {
        let want = name.isEmpty ? "" : (lproj[name] ?? "")
        guard want != savedCode else { return }   // already in this language
        let alert = NSAlert()
        alert.messageText = name.isEmpty ? "Use English for Verba's interface?"
                                         : "Switch Verba's interface to \(name)?"
        alert.informativeText = "Verba will restart to apply the language."
        alert.addButton(withTitle: "Restart")
        alert.addButton(withTitle: "Not now")
        if alert.runModal() == .alertFirstButtonReturn { applyUILanguage(name) }
    }
}

// MARK: - Crisp vector flags (drawn in SwiftUI, no assets / no SVG dependency)

/// A small, sharp flag chip for a Verba language NAME. Stripe flags are drawn exactly; flags that
/// don't reduce to stripes use a clean coloured chip with the language code, which stays crisp at
/// any size (far better than the flat emoji flags).
struct FlagView: View {
    let language: String
    var height: CGFloat = 14

    private var spec: Flag { Flag.of(language) }

    var body: some View {
        let w = height * 1.4
        Group {
            switch spec {
            case let .vertical(colors):   stripes(colors, vertical: true)
            case let .horizontal(colors): stripes(colors, vertical: false)
            case let .japan(bg, dot):
                ZStack { bg; Circle().fill(dot).frame(width: height * 0.6, height: height * 0.6) }
            case let .code(text, bg, fg):
                ZStack { bg; Text(text).font(.system(size: height * 0.62, weight: .bold)).foregroundStyle(fg) }
            case .globe:
                Image(systemName: "globe").font(.system(size: height * 0.95)).foregroundStyle(.secondary)
            }
        }
        .frame(width: spec.isGlobe ? height : w, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 3, style: .continuous).strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5))
    }

    private func stripes(_ colors: [Color], vertical: Bool) -> some View {
        let layout: AnyLayout = vertical ? AnyLayout(HStackLayout(spacing: 0)) : AnyLayout(VStackLayout(spacing: 0))
        return layout { ForEach(colors.indices, id: \.self) { colors[$0] } }
    }
}

enum Flag {
    case vertical([Color]), horizontal([Color]), japan(bg: Color, dot: Color), code(String, bg: Color, fg: Color), globe
    var isGlobe: Bool { if case .globe = self { return true }; return false }

    /// Every language is a black chip with its 2-letter country/lang code in white (consistent, crisp).
    static func of(_ language: String) -> Flag {
        let blk = Color.black, w = Color.white
        let codes: [String: String] = [
            "English": "EN", "French": "FR", "Spanish": "ES", "German": "DE", "Italian": "IT",
            "Portuguese": "PT", "Dutch": "NL", "Russian": "RU", "Chinese": "ZH", "Japanese": "JA",
            "Korean": "KO", "Arabic": "AR", "Hindi": "HI", "Turkish": "TR", "Polish": "PL",
        ]
        guard let c = codes[language] else { return .globe }
        return .code(c, bg: blk, fg: w)
    }
}

// MARK: - Footer language switcher

/// A compact flag button in the sidebar footer. Click opens the picker; choosing a language sets the
/// user's DEFAULT output language (so every mode writes in it), which avoids accidental wrong-language output.
struct FooterLanguageButton: View {
    @ObservedObject private var settings = Settings.shared

    var body: some View {
        Menu {
            Button { pick("") } label: {
                Label("Auto-detect", systemImage: settings.mainLanguage.isEmpty ? "checkmark" : "globe")
            }
            Divider()
            ForEach(translateLanguages, id: \.self) { lang in
                Button { pick(lang) } label: {
                    HStack {
                        Text(lang)
                        if settings.mainLanguage == lang { Spacer(); Image(systemName: "checkmark") }
                    }
                }
            }
        } label: {
            FlagView(language: settings.mainLanguage, height: 14)
        }
        .menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden).fixedSize()
        .help("Language — sets output language + offers to translate the interface")
    }

    /// Set the dictation OUTPUT language, then offer to also translate the interface (with a restart).
    private func pick(_ lang: String) {
        settings.mainLanguage = lang
        // Keep the Translate mode's target in sync with this one obvious control: picking a
        // language here used to leave Translate on its own separate target (default "English"),
        // so Translate appeared to "only work in English" no matter what the user chose. A real
        // language now drives BOTH; "Auto-detect" ("") leaves the last Translate target intact.
        if !lang.isEmpty { settings.setTranslateLanguage(lang) }
        LocaleManager.offerUISwitch(to: lang)
    }
}
