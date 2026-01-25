import SwiftUI

struct MenuBarView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()

            Divider()

            Picker("", selection: $selectedTab) {
                Text("CLI Tools").tag(0)
                Text("NPM Packages").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)

            Divider()

            Group {
                if selectedTab == 0 {
                    CLIToolsTabView()
                } else {
                    NpmPackagesTabView()
                }
            }
            .frame(maxHeight: 600)

            Divider()

            FooterView()
        }
        .frame(width: 380)
    }
}
