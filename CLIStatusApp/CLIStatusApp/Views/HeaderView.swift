import SwiftUI

struct HeaderView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack {
            Text("CLI Status")
                .font(.headline)

            Spacer()

            Button {
                Task { await appState.checkAll() }
            } label: {
                if appState.isChecking {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
            }
            .buttonStyle(.plain)
            .disabled(appState.isChecking)
            .help("Check for updates")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
