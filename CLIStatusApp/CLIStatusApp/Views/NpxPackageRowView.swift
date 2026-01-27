//
//  NpxPackageRowView.swift
//  CLIStatusApp
//
//  NPX 包行视图
//  显示包名称、版本状态和操作按钮
//

import SwiftUI

struct NpxPackageRowView: View {
    @Environment(AppState.self) private var appState
    @Bindable var package: NpxPackageStatus

    var body: some View {
        ListItemCard(statusType: cardStatusType) {
            HStack(spacing: AppSpacing.md) {
                npxIcon

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(package.name)
                        .font(.itemTitle)
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)

                    versionText
                }

                Spacer()

                actionButtons
            }
        }
        .padding(.horizontal, AppSpacing.sm)
    }

    private var npxIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppCornerRadius.xs)
                .fill(.ultraThinMaterial)
                .frame(width: 28, height: 28)
                .overlay {
                    RoundedRectangle(cornerRadius: AppCornerRadius.xs)
                        .stroke(Color.brandPrimary.opacity(0.35), lineWidth: 1)
                }

            Image(systemName: "terminal.fill")
                .font(.system(size: AppSize.Icon.md, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.brandPrimary)
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
        case .checking:
            ProgressView()
                .controlSize(.mini)
        case .updateAvailable:
            HStack(spacing: AppSpacing.xs) {
                ActionButton("更新", icon: "arrow.up", style: .primary, size: .small) {
                    appState.applyNpxUpdate(name: package.name)
                }

                IconButton(icon: "trash", style: .destructive, size: .small) {
                    appState.removeNpxPackage(name: package.name)
                }
            }
        case .upToDate, .error, .idle:
            IconButton(icon: "trash", style: .ghost, size: .small) {
                appState.removeNpxPackage(name: package.name)
            }
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
        Text("NpxPackageRowView Preview")
            .font(.appTitle)
    }
    .padding()
    .frame(width: 380)
}
