import SwiftUI

struct ToolRowView: View {
    @Environment(AppState.self) private var appState
    @Bindable var toolStatus: ToolStatus

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "terminal")
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(toolStatus.tool.displayName)
                    .font(.body.weight(.medium))

                versionText
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            actionButton
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundColor)
        )
        .padding(.horizontal, 8)
    }

    @ViewBuilder
    private var versionText: some View {
        switch toolStatus.state {
        case .idle, .checking:
            Text("Checking...")
        case .notInstalled:
            Text("Not installed")
                .foregroundStyle(.orange)
        case .upToDate(let current):
            Text("v\(current.display)")
                .foregroundStyle(.green)
        case .updateAvailable(let current, let latest):
            HStack(spacing: 4) {
                Text("v\(current.display)")
                Image(systemName: "arrow.right")
                    .font(.caption2)
                Text("v\(latest.display)")
                    .foregroundStyle(.green)
            }
        case .updating:
            Text("Updating...")
        case .installing:
            Text("Installing...")
        case .error(let message):
            Text(message)
                .foregroundStyle(.red)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        switch toolStatus.state {
        case .checking, .updating, .installing:
            ProgressView()
                .controlSize(.small)
                .frame(width: 60)
        case .notInstalled:
            Button("Install") {
                Task { await appState.install(toolStatus.tool) }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        case .updateAvailable:
            Button("Update") {
                Task { await appState.update(toolStatus.tool) }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        case .upToDate:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .frame(width: 60)
        case .error:
            Button {
                Task { await appState.checkAll() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        case .idle:
            EmptyView()
                .frame(width: 60)
        }
    }

    private var backgroundColor: Color {
        switch toolStatus.state {
        case .updateAvailable:
            return Color.orange.opacity(0.1)
        case .error:
            return Color.red.opacity(0.1)
        default:
            return Color.clear
        }
    }
}
