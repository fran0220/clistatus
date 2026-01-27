//
//  BrewPackagesTabView.swift
//  CLIStatusApp
//
//  Homebrew 包标签页视图
//  显示已安装的 Homebrew 包列表，支持安装新包
//

import SwiftUI

struct BrewPackagesTabView: View {
    @Environment(AppState.self) private var appState
    @State private var installSpec = ""
    @State private var isInstalling = false

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            sectionHeader

            installInputSection

            packageListContent
        }
        .padding(AppSpacing.md)
    }

    private var installInputSection: some View {
        HStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "cup.and.saucer")
                    .font(.system(size: AppSize.Icon.sm))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.textTertiary)

                TextField("包名称（如 wget 或 cask:iterm2）", text: $installSpec)
                    .textFieldStyle(.plain)
                    .font(.appBody)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background {
                RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                    .fill(.ultraThinMaterial)
            }
            .overlay {
                RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                    .stroke(Color.white.opacity(0.25), lineWidth: 0.6)
            }

            ActionButton(
                "安装",
                icon: "plus.circle",
                style: .primary,
                size: .medium,
                isLoading: isInstalling,
                isDisabled: installSpec.isEmpty
            ) {
                guard !installSpec.isEmpty else { return }
                isInstalling = true
                Task {
                    await appState.installBrewPackage(spec: installSpec)
                    installSpec = ""
                    isInstalling = false
                }
            }
        }
    }

    @ViewBuilder
    private var packageListContent: some View {
        if appState.isCheckingBrew && appState.brewPackages.isEmpty {
            loadingView
        } else if appState.brewPackages.isEmpty {
            emptyStateView
        } else {
            packageListView
        }
    }

    private var loadingView: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView()
                .controlSize(.regular)

            Text("正在加载 Homebrew 包...")
                .font(.appSubheadline)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            ZStack {
                Circle()
                    .fill(Color.brewAmber.opacity(0.08))
                    .frame(width: 72, height: 72)

                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 28, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.brewAmber)
            }

            VStack(spacing: AppSpacing.sm) {
                Text("暂无 Homebrew 包")
                    .font(.appTitle2)
                    .foregroundStyle(Color.textPrimary)

                Text("还没有安装 Homebrew 包。\n在上方输入包名进行安装。")
                    .font(.appSubheadline)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }

            ActionButton("刷新列表", icon: "arrow.clockwise", style: .secondary, size: .medium) {
                Task { await appState.checkBrewPackages() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppSpacing.xl)
    }

    private var packageListView: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.xs) {
                ForEach(appState.brewPackages) { package in
                    BrewPackageRowView(package: package)
                }
            }
            .padding(.vertical, AppSpacing.sm)
        }
    }

    private var sectionHeader: some View {
        HStack(spacing: AppSpacing.sm) {
            Text("Homebrew")
                .font(.appTitle2)
                .foregroundStyle(Color.textPrimary)

            Spacer()

            if appState.brewPackages.isEmpty {
                StatusBadge(type: .info, text: "暂无包", size: .small)
            } else if packagesWithUpdates > 0 {
                StatusBadge(type: .updateAvailable, text: "可更新 \(packagesWithUpdates)", size: .small)
            } else {
                StatusBadge(type: .installed, text: "已是最新", size: .small)
            }
        }
    }

    private var packagesWithUpdates: Int {
        appState.brewPackages.filter { package in
            if case .updateAvailable = package.state {
                return true
            }
            return false
        }.count
    }
}

#Preview {
    BrewPackagesTabView()
        .environment(AppState())
        .frame(width: 380, height: 400)
}
