import SwiftUI

struct CLIToolsTabView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(appState.tools) { toolStatus in
                    ToolRowView(toolStatus: toolStatus)
                }
            }
            .padding(.vertical, 8)
        }
    }
}
