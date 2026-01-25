import SwiftUI

struct FooterView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack {
            if let lastCheck = appState.lastCheckTime {
                Text("Last check: \(lastCheck, style: .relative)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            SettingsLink {
                Image(systemName: "gear")
            }
            .buttonStyle(.plain)

            Divider()
                .frame(height: 16)

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
