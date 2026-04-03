import SwiftUI

struct FooterView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack {
            if let lastCheck = appState.lastCheckTime {
                Label("上次: \(lastCheck, style: .relative)", systemImage: "clock")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else {
                Label("尚未检查", systemImage: "clock")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            SettingsLink {
                Label("设置", systemImage: "gear")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button(role: .destructive) {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("退出", systemImage: "power")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}
