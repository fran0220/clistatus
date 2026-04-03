import SwiftUI

struct HeaderView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack {
            Image(systemName: "terminal.fill")
                .foregroundStyle(.secondary)
            Text("CLI Status")
                .font(.headline)
            Spacer()
            Button {
                Task { await appState.checkAll() }
            } label: {
                HStack(spacing: 4) {
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
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
