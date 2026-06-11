import SwiftUI

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
            Button { settings.mainLanguage = "" } label: {
                Label("Auto-detect", systemImage: settings.mainLanguage.isEmpty ? "checkmark" : "globe")
            }
            Divider()
            ForEach(translateLanguages, id: \.self) { lang in
                Button { settings.mainLanguage = lang } label: {
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
        .help("Default output language")
    }
}
