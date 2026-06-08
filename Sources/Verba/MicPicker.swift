import SwiftUI

/// A small mic icon that opens the input-device menu. Lives in the sidebar's
/// account footer, just left of the settings gear. Same data + persistence as
/// the menu-bar Microphone submenu (Settings.micUID drives the recorder).
struct FooterMicButton: View {
    @ObservedObject var settings = Settings.shared
    @State private var devices: [MicDevices.Device] = []

    private var currentName: String {
        settings.micUID.isEmpty
            ? "System default"
            : (devices.first { $0.uid == settings.micUID }?.name
               ?? MicDevices.name(forUID: settings.micUID) ?? "Unavailable")
    }

    var body: some View {
        Menu {
            Button { settings.micUID = "" } label: {
                if settings.micUID.isEmpty { Label("System default", systemImage: "checkmark") }
                else { Text("System default") }
            }
            if !devices.isEmpty { Divider() }
            ForEach(devices) { d in
                Button { settings.micUID = d.uid } label: {
                    if d.uid == settings.micUID { Label(d.name, systemImage: "checkmark") }
                    else { Text(d.name) }
                }
            }
        } label: {
            Image(systemName: "mic.fill").foregroundStyle(.secondary)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Microphone: \(currentName)")
        .onAppear { devices = MicDevices.inputs() }
        .onChange(of: settings.micUID) { _, _ in devices = MicDevices.inputs() }
    }
}
