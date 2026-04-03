import SwiftUI

struct ToolRowView: View {
    @Environment(AppState.self) private var appState
    @Bindable var toolStatus: ToolStatus

    var body: some View {
        HStack(spacing: 10) {
            toolIcon
            VStack(alignment: .leading, spacing: 2) {
                Text(toolStatus.tool.displayName)
                    .font(.system(size: 13, weight: .medium))
                versionText
            }
            Spacer()
            actionContent
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 8).fill(.quaternary.opacity(0.5)))
    }

    private var toolIcon: some View {
        Group {
            if let officialIcon = toolStatus.tool.officialIconImage {
                officialIcon
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
            } else {
                Image(systemName: toolStatus.tool.iconName)
                    .font(.system(size: 18))
                    .foregroundStyle(toolStatus.tool.iconColor)
                    .frame(width: 28, height: 28)
            }
        }
    }

    @ViewBuilder
    private var versionText: some View {
        switch toolStatus.state {
        case .idle, .checking:
            HStack(spacing: 4) {
                ProgressView().controlSize(.mini)
                Text("检查中...").font(.caption).foregroundStyle(.tertiary)
            }
        case .notInstalled:
            Text("未安装").font(.caption).foregroundStyle(.red)
        case .upToDate(let current):
            Text("v\(current.display)").font(.system(size: 11, design: .monospaced)).foregroundStyle(.green)
        case .updateAvailable(let current, let latest):
            HStack(spacing: 4) {
                Text("v\(current.display)").font(.system(size: 11, design: .monospaced)).foregroundStyle(.secondary)
                Image(systemName: "arrow.right").font(.system(size: 8, weight: .bold)).foregroundStyle(.orange)
                Text("v\(latest.display)").font(.system(size: 11, design: .monospaced)).foregroundStyle(.green)
            }
        case .updating:
            HStack(spacing: 4) {
                ProgressView().controlSize(.mini)
                Text("更新中...").font(.caption).foregroundStyle(.tertiary)
            }
        case .installing:
            HStack(spacing: 4) {
                ProgressView().controlSize(.mini)
                Text("安装中...").font(.caption).foregroundStyle(.tertiary)
            }
        case .error(let message):
            Text(message).font(.caption).foregroundStyle(.red).lineLimit(1)
        }
    }

    @ViewBuilder
    private var actionContent: some View {
        switch toolStatus.state {
        case .checking, .updating, .installing:
            ProgressView().controlSize(.small)
        case .notInstalled:
            Button("安装") { Task { await appState.install(toolStatus.tool) } }
                .controlSize(.small)
        case .updateAvailable:
            Button("更新") { Task { await appState.update(toolStatus.tool) } }
                .controlSize(.small)
                .tint(.accentColor)
        case .upToDate:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.system(size: 14))
        case .error:
            Button("重试") { Task { await appState.checkAll() } }
                .controlSize(.small)
        case .idle:
            EmptyView()
        }
    }
}
