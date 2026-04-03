import SwiftUI

struct NpmPackageRowView: View {
    @Environment(AppState.self) private var appState
    @Bindable var package: NpmPackageStatus

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "shippingbox.fill")
                .foregroundStyle(.red.opacity(0.7))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(package.name)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                versionText
            }

            Spacer()
            actionButtons
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 8).fill(.quaternary.opacity(0.5)))
    }

    @ViewBuilder
    private var versionText: some View {
        switch package.state {
        case .idle, .checking:
            HStack(spacing: 4) {
                ProgressView().controlSize(.mini)
                Text("检查中...").font(.caption2).foregroundStyle(.tertiary)
            }
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
                Text("更新中...").font(.caption2).foregroundStyle(.tertiary)
            }
        case .uninstalling:
            HStack(spacing: 4) {
                ProgressView().controlSize(.mini)
                Text("卸载中...").font(.caption2).foregroundStyle(.tertiary)
            }
        case .error(let message):
            Text(message).font(.caption2).foregroundStyle(.red).lineLimit(1)
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        switch package.state {
        case .checking, .updating, .uninstalling:
            ProgressView().controlSize(.mini)
        case .updateAvailable:
            HStack(spacing: 4) {
                Button("更新") { Task { await appState.upgradeNpmPackage(name: package.name) } }
                    .controlSize(.mini)
                Button(role: .destructive) { Task { await appState.uninstallNpmPackage(name: package.name) } } label: {
                    Image(systemName: "trash")
                }
                .controlSize(.mini)
            }
        case .upToDate:
            Button(role: .destructive) { Task { await appState.uninstallNpmPackage(name: package.name) } } label: {
                Image(systemName: "trash")
            }
            .controlSize(.mini)
            .opacity(0.6)
        case .error:
            Button("重试") { Task { await appState.checkNpmPackages() } }
                .controlSize(.mini)
        case .idle:
            EmptyView()
        }
    }
}
