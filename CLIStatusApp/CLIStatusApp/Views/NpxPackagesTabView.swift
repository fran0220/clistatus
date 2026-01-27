//
//  NpxPackagesTabView.swift
//  CLIStatusApp
//
//  NPX 包标签页视图
//  管理需要追踪的 NPX 包
//

import SwiftUI

struct NpxPackagesTabView: View {
    @Environment(AppState.self) private var appState
    @State private var packageName = ""
    @State private var isAdding = false

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            sectionHeader

            addInputSection

            packageListContent
        }
        .padding(AppSpacing.md)
    }

    private var addInputSection: some View {
        HStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "terminal")
                    .font(.system(size: AppSize.Icon.sm))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.textTertiary)

                TextField("包名称（如 eslint）", text: $packageName)
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
                "添加",
                icon: "plus.circle",
                style: .primary,
                size: .medium,
                isLoading: isAdding,
                isDisabled: packageName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ) {
                guard !packageName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                isAdding = true
                Task {
                    await appState.addNpxPackage(name: packageName)
                    packageName = ""
                    isAdding = false
                }
            }
        }
    }

    @ViewBuilder
    private var packageListContent: some View {
        if appState.isCheckingNpx && appState.npxPackages.isEmpty {
            loadingView
        } else if appState.npxPackages.isEmpty {
            emptyStateView
        } else {
            packageListView
        }
    }

    private var loadingView: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView()
                .controlSize(.regular)

            Text("正在加载 NPX 包...")
                .font(.appSubheadline)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            ZStack {
                Circle()
                    .fill(Color.brandPrimary.opacity(0.08))
                    .frame(width: 72, height: 72)

                Image(systemName: "terminal")
                    .font(.system(size: 28, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.brandPrimary)
            }

            VStack(spacing: AppSpacing.sm) {
                Text("暂无 NPX 包")
                    .font(.appTitle2)
                    .foregroundStyle(Color.textPrimary)

                Text("添加需要追踪的 NPX 包。\n我们会检测最新版本。")
                    .font(.appSubheadline)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }

            ActionButton("刷新列表", icon: "arrow.clockwise", style: .secondary, size: .medium) {
                Task { await appState.checkNpxPackages() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppSpacing.xl)
    }

    private var packageListView: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.xs) {
                ForEach(appState.npxPackages) { package in
                    NpxPackageRowView(package: package)
                }
            }
            .padding(.vertical, AppSpacing.sm)
        }
    }

    private var sectionHeader: some View {
        HStack(spacing: AppSpacing.sm) {
            Text("NPX 包")
                .font(.appTitle2)
                .foregroundStyle(Color.textPrimary)

            Spacer()

            if appState.npxPackages.isEmpty {
                StatusBadge(type: .info, text: "未追踪", size: .small)
            } else if packagesWithUpdates > 0 {
                StatusBadge(type: .updateAvailable, text: "可更新 \(packagesWithUpdates)", size: .small)
            } else {
                StatusBadge(type: .installed, text: "已是最新", size: .small)
            }
        }
    }

    private var packagesWithUpdates: Int {
        appState.npxPackages.filter { package in
            if case .updateAvailable = package.state {
                return true
            }
            return false
        }.count
    }
}

#Preview {
    NpxPackagesTabView()
        .environment(AppState())
        .frame(width: 380, height: 400)
}
