import SwiftUI

struct HeaderView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "terminal.fill")
                .foregroundStyle(.secondary)
            Text("CLI Status")
                .font(.headline)
            Spacer(minLength: 0)
            Button {
                Task { await appState.checkAll() }
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    if appState.isChecking {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    Text(appState.isChecking ? "检查中" : "刷新")
                        .font(.caption)
                }
            }
            .disabled(appState.isChecking)
            .accessibilityLabel(appState.isChecking ? "正在检查" : "刷新全部")
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }
}
