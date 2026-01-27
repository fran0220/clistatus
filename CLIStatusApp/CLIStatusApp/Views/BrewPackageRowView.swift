//
//  BrewPackageRowView.swift
//  CLIStatusApp
//
//  Homebrew 包行视图
//  显示包名称、版本状态和操作按钮
//

import SwiftUI

struct BrewPackageRowView: View {
    @Environment(AppState.self) private var appState
    @Bindable var package: BrewPackageStatus

    var body: some View {
        ListItemCard(statusType: cardStatusType) {
            HStack(spacing: AppSpacing.md) {
                brewIcon

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack(spacing: AppSpacing.xs) {
                        Text(package.name)
                            .font(.itemTitle)
                            .foregroundStyle(Color.textPrimary)
                            .lineLimit(1)

                        kindBadge
                    }

                    versionText
                }

                Spacer()

                actionButtons
            }
        }
        .padding(.horizontal, AppSpacing.sm)
    }

    private var brewIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppCornerRadius.xs)
                .fill(.ultraThinMaterial)
                .frame(width: 28, height: 28)
                .overlay {
                    RoundedRectangle(cornerRadius: AppCornerRadius.xs)
                        .stroke(Color.brewAmber.opacity(0.4), lineWidth: 1)
                }

            Image(systemName: package.kind == .cask ? "app.fill" : "cup.and.saucer.fill")
                .font(.system(size: AppSize.Icon.md, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.brewAmber)
        }
    }

    private var kindBadge: some View {
        Text(package.kind == .cask ? "Cask" : "Formula")
            .font(.appCaption2)
            .foregroundStyle(Color.textSecondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
            }
            .overlay {
                Capsule()
                    .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
            }
    }

    @ViewBuilder
    private var versionText: some View {
        switch package.state {
        case .idle, .checking:
            HStack(spacing: AppSpacing.xs) {
                ProgressView()
                    .controlSize(.mini)
                Text("检查中...")
                    .font(.appCaption2)
                    .foregroundStyle(Color.textTertiary)
            }

        case .upToDate(let current):
            Text(current)
                .font(.version)
                .foregroundStyle(Color.statusSuccess)

        case .updateAvailable(let current, let latest):
            HStack(spacing: AppSpacing.xs) {
                Text(current)
                    .font(.appCodeSmall)
                    .foregroundStyle(Color.textSecondary)

                Image(systemName: "arrow.right")
                    .font(.system(size: 8, weight: .bold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.statusWarning)

                Text(latest)
                    .font(.version)
                    .foregroundStyle(Color.statusSuccess)
            }

        case .updating:
            HStack(spacing: AppSpacing.xs) {
                ProgressView()
                    .controlSize(.mini)
                Text("更新中...")
                    .font(.appCaption2)
                    .foregroundStyle(Color.textTertiary)
            }

        case .uninstalling:
            HStack(spacing: AppSpacing.xs) {
                ProgressView()
                    .controlSize(.mini)
                Text("卸载中...")
                    .font(.appCaption2)
                    .foregroundStyle(Color.textTertiary)
            }

        case .error(let message):
            Text(message)
                .font(.appCaption2)
                .foregroundStyle(Color.statusError)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        switch package.state {
        case .checking, .updating, .uninstalling:
            ProgressView()
                .controlSize(.mini)

        case .updateAvailable:
            HStack(spacing: AppSpacing.xs) {
                ActionButton("更新", icon: "arrow.up", style: .primary, size: .small) {
                    Task { await appState.upgradeBrewPackage(name: package.name) }
                }

                IconButton(icon: "trash", style: .destructive, size: .small) {
                    Task { await appState.uninstallBrewPackage(name: package.name) }
                }
            }

        case .upToDate:
            IconButton(icon: "trash", style: .ghost, size: .small) {
                Task { await appState.uninstallBrewPackage(name: package.name) }
            }

        case .error:
            ActionButton("重试", icon: "arrow.clockwise", style: .secondary, size: .small) {
                Task { await appState.checkBrewPackages() }
            }

        case .idle:
            EmptyView()
        }
    }

    private var cardStatusType: StatusType? {
        switch package.state {
        case .updateAvailable:
            return .updateAvailable
        case .error:
            return .error
        default:
            return nil
        }
    }
}

#Preview {
    VStack(spacing: AppSpacing.sm) {
        Text("BrewPackageRowView Preview")
            .font(.appTitle)
    }
    .padding()
    .frame(width: 380)
}
