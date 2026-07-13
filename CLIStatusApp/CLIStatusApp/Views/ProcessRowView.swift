import SwiftUI

struct ProcessRowView: View {
    let process: ProcessStatus
    var compact: Bool = false
    let onTerminate: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            if !compact {
                Image(systemName: "app.dashed")
                    .foregroundStyle(Color.metricCPU.opacity(0.75))
                    .frame(width: 24)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(compact ? process.name : process.displayName)
                        .font(compact ? .caption : .appRowTitle)
                        .lineLimit(1)

                    Text("PID \(process.pid)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                }

                HStack(spacing: AppSpacing.sm) {
                    MetricPill(
                        title: "CPU",
                        value: "\(process.cpuPercent.formatted(.number.precision(.fractionLength(1))))%",
                        color: .metricCPU
                    )
                    MetricPill(
                        title: "内存",
                        value: memoryLabel(process.residentMemoryMB),
                        color: .metricMemory
                    )
                }
            }

            Spacer(minLength: 4)

            Button(role: .destructive) {
                onTerminate()
            } label: {
                Image(systemName: "stop.circle")
            }
            .controlSize(.mini)
            .disabled(!process.canTerminate)
            .opacity(process.canTerminate ? 0.75 : 0.25)
            .help(process.canTerminate ? "停止进程" : "不能停止该进程")
            .accessibilityLabel("停止进程")
        }
        .padding(.horizontal, compact ? AppSpacing.sm : AppSpacing.sm + 2)
        .padding(.vertical, compact ? AppSpacing.xs + 1 : AppSpacing.sm - 1)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                .fill(compact ? Color.primary.opacity(0.04) : Color.surfaceRow)
        )
    }

    private func memoryLabel(_ mb: Double) -> String {
        if mb >= 1024 {
            return "\((mb / 1024).formatted(.number.precision(.fractionLength(1)))) GB"
        }
        return "\(mb.formatted(.number.precision(.fractionLength(mb >= 100 ? 0 : 1)))) MB"
    }
}
