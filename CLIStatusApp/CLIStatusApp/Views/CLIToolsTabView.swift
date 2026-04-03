import SwiftUI

struct CLIToolsTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if appState.tools.isEmpty {
            ContentUnavailableView("暂无 CLI 工具", systemImage: "terminal", description: Text("请检查配置或稍后重试"))
        } else {
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(appState.tools) { toolStatus in
                        ToolRowView(toolStatus: toolStatus)
                    }
                }
                .padding(8)
            }
        }
    }
}
