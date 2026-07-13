import SwiftUI

struct PerformanceTabView: View {
    @Environment(AppState.self) private var appState
    @State private var sortMode: ProcessSortMode = .memory
    @State private var processToTerminate: ProcessStatus?

    private var rankedGroups: [ProcessGroup] {
        appState.sortedProcessGroups(by: sortMode)
    }

    private var maxMetric: Double {
        switch sortMode {
        case .memory:
            return max(rankedGroups.map(\.totalMemoryMB).max() ?? 1, 1)
        case .cpu:
            return max(rankedGroups.map(\.totalCPU).max() ?? 1, 1)
        }
    }

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            summarySection
                .padding(.horizontal, AppSpacing.sm)
                .padding(.top, AppSpacing.sm)

            controls
                .padding(.horizontal, AppSpacing.sm)

            if let error = appState.processMonitorError {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(Color.statusError)
                    .lineLimit(2)
                    .padding(.horizontal, AppSpacing.sm)
            }

            if let processToTerminate {
                terminationConfirmView(for: processToTerminate)
                    .padding(.horizontal, AppSpacing.sm)
            }

            if appState.isRefreshingProcesses && rankedGroups.isEmpty {
                Spacer()
                ProgressView("正在加载进程...")
                Spacer()
            } else if rankedGroups.isEmpty {
                ContentUnavailableView(
                    "暂无进程数据",
                    systemImage: "cpu",
                    description: Text("点击刷新重新读取系统状态")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: AppSpacing.xs) {
                        ForEach(Array(rankedGroups.enumerated()), id: \.element.id) { index, group in
                            ProcessGroupRowView(
                                group: group,
                                rank: index + 1,
                                relativeShare: relativeShare(for: group),
                                sortMode: sortMode
                            ) { process in
                                processToTerminate = process
                            }
                        }
                    }
                    .padding(AppSpacing.sm)
                }
            }
        }
        .task {
            await appState.refreshProcesses()
            appState.startProcessAutoRefreshIfNeeded()
        }
        .onDisappear {
            appState.stopProcessAutoRefresh()
        }
    }

    private func relativeShare(for group: ProcessGroup) -> Double {
        switch sortMode {
        case .memory:
            return group.totalMemoryMB / maxMetric
        case .cpu:
            return group.totalCPU / maxMetric
        }
    }

    private var summarySection: some View {
        HStack(spacing: AppSpacing.sm) {
            ResourceCardView(
                title: "CPU",
                value: appState.processSnapshot.map {
                    "\($0.cpuUsagePercent.formatted(.number.precision(.fractionLength(0))))%"
                } ?? "--",
                subtitle: "总占用",
                systemImage: "cpu",
                color: .metricCPU,
                progress: appState.processSnapshot?.cpuUsagePercent
            )

            ResourceCardView(
                title: "内存",
                value: appState.processSnapshot.map {
                    "\($0.memoryUsagePercent.formatted(.number.precision(.fractionLength(0))))%"
                } ?? "--",
                subtitle: appState.processSnapshot.map {
                    "\($0.memoryUsedGB.formatted(.number.precision(.fractionLength(1)))) / \($0.memoryTotalGB.formatted(.number.precision(.fractionLength(1)))) GB"
                } ?? "--",
                systemImage: "memorychip",
                color: .metricMemory,
                progress: appState.processSnapshot?.memoryUsagePercent
            )
        }
    }

    private var controls: some View {
        HStack(spacing: AppSpacing.sm) {
            Picker("排序", selection: $sortMode) {
                ForEach(ProcessSortMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Button {
                Task { await appState.refreshProcesses() }
            } label: {
                if appState.isRefreshingProcesses {
                    ProgressView().controlSize(.mini)
                } else {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .disabled(appState.isRefreshingProcesses)
            .help("刷新")
            .accessibilityLabel("刷新进程")
        }
    }

    private func terminationConfirmView(for process: ProcessStatus) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.statusWarning)
                VStack(alignment: .leading, spacing: 2) {
                    Text("停止 \(process.displayName)？")
                        .font(.system(size: 12, weight: .semibold))
                    Text("PID \(process.pid)。未保存的数据可能丢失。")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: AppSpacing.sm) {
                Spacer()
                Button("取消") {
                    processToTerminate = nil
                }
                .controlSize(.small)

                Button("停止", role: .destructive) {
                    let pid = process.pid
                    processToTerminate = nil
                    Task { await appState.stopProcess(pid: pid) }
                }
                .controlSize(.small)
            }
        }
        .padding(AppSpacing.sm + 2)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.lg - 2)
                .fill(Color.statusWarning.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.lg - 2)
                .stroke(Color.statusWarning.opacity(0.35), lineWidth: 1)
        )
    }
}
