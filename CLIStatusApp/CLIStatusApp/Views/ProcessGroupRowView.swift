import AppKit
import SwiftUI

struct ProcessGroupRowView: View {
    let group: ProcessGroup
    let rank: Int
    let relativeShare: Double
    let sortMode: ProcessSortMode
    let onTerminate: (ProcessStatus) -> Void

    @State private var isExpanded = false

    private var showsDisclosure: Bool {
        group.memberCount > 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            headerRow

            UsageBarView(
                progress: relativeShare,
                color: sortMode == .memory ? .metricMemory : .metricCPU,
                height: 4
            )

            if isExpanded && showsDisclosure {
                VStack(spacing: AppSpacing.xs) {
                    ForEach(group.members) { process in
                        ProcessRowView(process: process, compact: true) {
                            onTerminate(process)
                        }
                    }
                }
                .padding(.leading, AppSpacing.md)
            }
        }
        .padding(.horizontal, AppSpacing.sm + 2)
        .padding(.vertical, AppSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.md)
                .fill(Color.surfaceRow)
        )
    }

    private var headerRow: some View {
        HStack(alignment: .center, spacing: AppSpacing.sm) {
            Text("#\(rank)")
                .font(.appRank)
                .foregroundStyle(Color.rankMuted)
                .frame(width: 28, alignment: .leading)

            appIcon
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(group.displayName)
                        .font(.appRowTitle)
                        .lineLimit(1)

                    if group.memberCount > 1 {
                        Text("\(group.memberCount)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(Color.primary.opacity(0.08)))
                    }
                }

                HStack(spacing: AppSpacing.sm) {
                    MetricPill(
                        title: "CPU",
                        value: "\(group.totalCPU.formatted(.number.precision(.fractionLength(1))))%",
                        color: .metricCPU
                    )
                    MetricPill(
                        title: "内存",
                        value: memoryLabel(group.totalMemoryMB),
                        color: .metricMemory
                    )
                    Text(shareLabel)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                }
            }

            Spacer(minLength: 4)

            if showsDisclosure {
                Button {
                    withAnimation(.easeOut(duration: 0.15)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isExpanded ? "折叠进程" : "展开进程")
            } else if let process = group.primaryProcess {
                Button(role: .destructive) {
                    onTerminate(process)
                } label: {
                    Image(systemName: "stop.circle")
                }
                .controlSize(.mini)
                .disabled(!process.canTerminate)
                .opacity(process.canTerminate ? 0.75 : 0.25)
                .help(process.canTerminate ? "停止进程" : "不能停止该进程")
            }
        }
    }

    @ViewBuilder
    private var appIcon: some View {
        if let url = group.bundleURL {
            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                .resizable()
                .interpolation(.high)
                .frame(width: 24, height: 24)
        } else {
            Image(systemName: "app.dashed")
                .foregroundStyle(Color.metricCPU.opacity(0.75))
                .frame(width: 24, height: 24)
        }
    }

    private var shareLabel: String {
        let percent = group.memoryShareOfSystem * 100
        return "\(percent.formatted(.number.precision(.fractionLength(percent >= 10 ? 0 : 1))))% 系统"
    }

    private func memoryLabel(_ mb: Double) -> String {
        if mb >= 1024 {
            return "\((mb / 1024).formatted(.number.precision(.fractionLength(1)))) GB"
        }
        return "\(mb.formatted(.number.precision(.fractionLength(mb >= 100 ? 0 : 1)))) MB"
    }
}
