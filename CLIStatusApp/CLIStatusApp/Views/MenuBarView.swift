import SwiftUI

struct MenuBarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()

            Divider()

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(appState.tools) { toolStatus in
                        ToolRowView(toolStatus: toolStatus)
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(maxHeight: 300)

            Divider()

            FooterView()
        }
        .frame(width: 320)
    }
}
