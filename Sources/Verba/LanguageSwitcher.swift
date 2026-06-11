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

    static func of(_ language: String) -> Flag {
        let r = Color(red: 0.84, green: 0.16, blue: 0.16)
        let b = Color(red: 0.0,  green: 0.22, blue: 0.66)
        let g = Color(red: 0.0,  green: 0.55, blue: 0.27)
        let y = Color(red: 0.98, green: 0.82, blue: 0.18)
        let blk = Color.black, w = Color.white
        switch language {
        case "French":     return .vertical([b, w, r])
        case "Italian":    return .vertical([g, w, r])
        case "German":     return .horizontal([blk, r, y])
        case "Dutch":      return .horizontal([r, w, b])
        case "Russian":    return .horizontal([w, b, r])
        case "Polish":     return .horizontal([w, r])
        case "Spanish":    return .horizontal([r, y, y, r])     // approx: yellow band wider
        case "Portuguese": return .vertical([g, g, r, r, r])
        case "Japanese":   return .japan(bg: w, dot: r)
        case "English":    return .code("EN", bg: b, fg: w)
        case "Chinese":    return .code("中", bg: r, fg: y)
        case "Korean":     return .code("한", bg: w, fg: b)
        case "Arabic":     return .code("ع", bg: g, fg: w)
        case "Hindi":      return .code("हि", bg: Color(red: 1, green: 0.6, blue: 0.2), fg: w)
        case "Turkish":    return .code("TR", bg: r, fg: w)
        default:           return .globe
        }
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
