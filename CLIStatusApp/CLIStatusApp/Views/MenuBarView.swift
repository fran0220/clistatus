import SwiftUI

struct MenuBarView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab: MainTab = .cli

    var body: some View {
        VStack(spacing: 8) {
            HeaderView()

            Picker("", selection: $selectedTab) {
                ForEach(MainTab.allCases) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 8)

            tabContent
                .frame(height: 480)

            FooterView()
        }
        .padding(8)
        .frame(width: 360)
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .cli:
            CLIToolsTabView()
        case .npm:
            NpmPackagesTabView()
        case .clipboard:
            ClipboardTabView()
        }
    }
}

private enum MainTab: Int, CaseIterable, Identifiable {
    case cli
    case npm
    case clipboard

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .cli: return "CLI 工具"
        case .npm: return "NPM 包"
        case .clipboard: return "剪贴板"
        }
    }
}
