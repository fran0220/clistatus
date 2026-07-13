import SwiftUI

struct FooterView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            if let lastCheck = appState.lastCheckTime {
                Label("上次: \(lastCheck, style: .relative)", systemImage: "clock")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else {
                Label("尚未检查", systemImage: "clock")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 0)

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
            .accessibilityLabel("退出应用")
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.xs + 2)
    }
}
