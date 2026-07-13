import SwiftUI

struct ToolRowView: View {
    @Environment(AppState.self) private var appState
    @Bindable var toolStatus: ToolStatus

    var body: some View {
        SurfaceRow {
            HStack(spacing: AppSpacing.sm) {
                toolIcon
                VStack(alignment: .leading, spacing: 2) {
                    Text(toolStatus.tool.displayName)
                        .font(.appRowTitle)
                    versionText
                }
                Spacer(minLength: 0)
                actionContent
            }
        }
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
            HStack(spacing: AppSpacing.xs) {
                ProgressView().controlSize(.mini)
                StatusBadge(type: .loading)
            }
        case .notInstalled:
            StatusBadge(type: .notInstalled)
        case .upToDate(let current):
            HStack(spacing: AppSpacing.xs) {
                Text("v\(current.display)")
                    .font(.appCode)
                    .foregroundStyle(Color.statusSuccess)
                    .monospacedDigit()
                StatusBadge(type: .installed, text: "最新")
            }
        case .updateAvailable(let current, let latest):
            HStack(spacing: AppSpacing.xs) {
                Text("v\(current.display)")
                    .font(.appCode)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Image(systemName: "arrow.right")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color.statusWarning)
                Text("v\(latest.display)")
                    .font(.appCode)
                    .foregroundStyle(Color.statusSuccess)
                    .monospacedDigit()
                StatusBadge(type: .updateAvailable)
            }
        case .updating:
            HStack(spacing: AppSpacing.xs) {
                ProgressView().controlSize(.mini)
                Text("更新中...").font(.caption).foregroundStyle(.tertiary)
            }
        case .installing:
            HStack(spacing: AppSpacing.xs) {
                ProgressView().controlSize(.mini)
                Text("安装中...").font(.caption).foregroundStyle(.tertiary)
            }
        case .error(let message):
            Text(message)
                .font(.caption)
                .foregroundStyle(Color.statusError)
                .lineLimit(1)
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
                .foregroundStyle(Color.statusSuccess)
                .font(.system(size: 14))
        case .error:
            Button("重试") { Task { await appState.checkAll() } }
                .controlSize(.small)
        case .idle:
            EmptyView()
        }
    }
}
