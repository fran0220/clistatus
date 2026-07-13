import SwiftUI

struct NpmPackageRowView: View {
    @Environment(AppState.self) private var appState
    @Bindable var package: NpmPackageStatus

    var body: some View {
        SurfaceRow {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "shippingbox.fill")
                    .foregroundStyle(Color.statusError.opacity(0.7))
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(package.name)
                        .font(.appRowTitle)
                        .lineLimit(1)
                    versionText
                }

                Spacer(minLength: 0)
                actionButtons
            }
        }
    }

    @ViewBuilder
    private var versionText: some View {
        switch package.state {
        case .idle, .checking:
            HStack(spacing: AppSpacing.xs) {
                ProgressView().controlSize(.mini)
                StatusBadge(type: .loading)
            }
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
                Text("更新中...").font(.caption2).foregroundStyle(.tertiary)
            }
        case .uninstalling:
            HStack(spacing: AppSpacing.xs) {
                ProgressView().controlSize(.mini)
                Text("卸载中...").font(.caption2).foregroundStyle(.tertiary)
            }
        case .error(let message):
            Text(message)
                .font(.caption2)
                .foregroundStyle(Color.statusError)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        switch package.state {
        case .checking, .updating, .uninstalling:
            ProgressView().controlSize(.mini)
        case .updateAvailable:
            HStack(spacing: AppSpacing.xs) {
                Button("更新") { Task { await appState.upgradeNpmPackage(name: package.name) } }
                    .controlSize(.mini)
                Button(role: .destructive) {
                    Task { await appState.uninstallNpmPackage(name: package.name) }
                } label: {
                    Image(systemName: "trash")
                }
                .controlSize(.mini)
                .accessibilityLabel("卸载包")
            }
        case .upToDate:
            Button(role: .destructive) {
                Task { await appState.uninstallNpmPackage(name: package.name) }
            } label: {
                Image(systemName: "trash")
            }
            .controlSize(.mini)
            .opacity(0.6)
            .accessibilityLabel("卸载包")
        case .error:
            Button("重试") { Task { await appState.checkNpmPackages() } }
                .controlSize(.mini)
        case .idle:
            EmptyView()
        }
    }
}
