import SwiftUI

struct PerformanceTabView: View {
    @Environment(AppState.self) private var appState
    @State private var sortMode: ProcessSortMode = .cpu
    @State private var processToTerminate: ProcessStatus?

    private var sortedProcesses: [ProcessStatus] {
        switch sortMode {
        case .cpu:
            appState.processes.sorted { $0.cpuPercent > $1.cpuPercent }
        case .memory:
            appState.processes.sorted { $0.residentMemoryMB > $1.residentMemoryMB }
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            summarySection
                .padding(.horizontal, 8)
                .padding(.top, 8)

            controls
                .padding(.horizontal, 8)

            if let error = appState.processMonitorError {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.red)
                    .lineLimit(2)
                    .padding(.horizontal, 8)
            }

            if let processToTerminate {
                terminationConfirmView(for: processToTerminate)
                    .padding(.horizontal, 8)
            }

            if appState.isRefreshingProcesses && appState.processes.isEmpty {
                Spacer()
                ProgressView("正在加载进程...")
                Spacer()
            } else if appState.processes.isEmpty {
                ContentUnavailableView("暂无进程数据", systemImage: "cpu", description: Text("点击刷新重新读取系统状态"))
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(sortedProcesses) { process in
                            ProcessRowView(process: process) {
                                processToTerminate = process
                            }
                        }
                    }
                    .padding(8)
                }
            }
        }
        .task {
            if appState.processes.isEmpty {
                await appState.refreshProcesses()
            }
        }
    }

    private var summarySection: some View {
        HStack(spacing: 8) {
            ResourceCardView(
                title: "CPU",
                value: appState.processSnapshot.map { "\($0.cpuUsagePercent.formatted(.number.precision(.fractionLength(0))))%" } ?? "--",
                subtitle: "总占用",
                systemImage: "cpu",
                color: .blue
            )

            ResourceCardView(
                title: "内存",
                value: appState.processSnapshot.map { "\($0.memoryUsagePercent.formatted(.number.precision(.fractionLength(0))))%" } ?? "--",
                subtitle: appState.processSnapshot.map { "\($0.memoryUsedGB.formatted(.number.precision(.fractionLength(1)))) / \($0.memoryTotalGB.formatted(.number.precision(.fractionLength(1)))) GB" } ?? "--",
                systemImage: "memorychip",
                color: .purple
            )
        }
    }

    private var controls: some View {
        HStack(spacing: 8) {
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
        }
    }

    private func terminationConfirmView(for process: ProcessStatus) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("停止 \(process.name)？")
                        .font(.system(size: 12, weight: .semibold))
                    Text("PID \(process.pid)。未保存的数据可能丢失。")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            HStack(spacing: 8) {
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
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(.orange.opacity(0.12)))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.orange.opacity(0.35), lineWidth: 1)
        )
    }
}

private enum ProcessSortMode: Int, CaseIterable, Identifiable {
    case cpu
    case memory

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .cpu: return "CPU"
        case .memory: return "内存"
        }
    }
}

private struct ResourceCardView: View {
    let title: String
    let value: String
    let subtitle: String
    let systemImage: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: systemImage)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Text(value)
                .font(.system(size: 22, weight: .semibold, design: .rounded))

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(.quaternary.opacity(0.45)))
    }
}
