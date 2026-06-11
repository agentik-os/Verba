import SwiftUI

/// Maps a Verba language NAME to a flag emoji (native, no assets). Auto-detect uses a globe.
func languageFlag(_ name: String) -> String {
    switch name {
    case "English":    return "🇬🇧"
    case "French":     return "🇫🇷"
    case "Spanish":    return "🇪🇸"
    case "German":     return "🇩🇪"
    case "Italian":    return "🇮🇹"
    case "Portuguese": return "🇵🇹"
    case "Dutch":      return "🇳🇱"
    case "Russian":    return "🇷🇺"
    case "Chinese":    return "🇨🇳"
    case "Japanese":   return "🇯🇵"
    case "Korean":     return "🇰🇷"
    case "Arabic":     return "🇸🇦"
    case "Hindi":      return "🇮🇳"
    case "Turkish":    return "🇹🇷"
    case "Polish":     return "🇵🇱"
    default:           return "🌐"
    }
}

/// A compact flag button in the sidebar footer that switches the output (primary) language fast.
/// Left-click toggles between the two most recent languages; the menu picks any of them.
struct FooterLanguageButton: View {
    @ObservedObject private var settings = Settings.shared
    @AppStorage("language.previous") private var previous = ""

    var body: some View {
        Menu {
            Button { pick("") } label: {
                Label("Auto-detect", systemImage: settings.mainLanguage.isEmpty ? "checkmark" : "globe")
            }
            Divider()
            ForEach(translateLanguages, id: \.self) { lang in
                Button { pick(lang) } label: {
                    HStack {
                        Text("\(languageFlag(lang))  \(lang)")
                        if settings.mainLanguage == lang { Spacer(); Image(systemName: "checkmark") }
                    }
                }
            }
        } label: {
            Text(settings.mainLanguage.isEmpty ? "🌐" : languageFlag(settings.mainLanguage))
                .font(.system(size: 15))
        } primaryAction: {
            // One-click flip between the current and the previously-used language.
            if !previous.isEmpty, previous != settings.mainLanguage { pick(previous) }
        }
        .menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden).fixedSize()
        .help("Output language — click to flip, menu to choose")
    }

    private func pick(_ lang: String) {
        guard lang != settings.mainLanguage else { return }
        previous = settings.mainLanguage    // remember the one we're leaving, for the quick flip
        settings.mainLanguage = lang
    }
}
