import SwiftUI

struct ProcessRowView: View {
    let process: ProcessStatus
    let onTerminate: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "app.dashed")
                .foregroundStyle(.blue.opacity(0.75))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(process.name)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)

                    Text("PID \(process.pid)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }

                Text(process.command)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    MetricPill(title: "CPU", value: "\(process.cpuPercent.formatted(.number.precision(.fractionLength(1))))%", color: .blue)
                    MetricPill(title: "内存", value: "\(process.residentMemoryMB.formatted(.number.precision(.fractionLength(process.residentMemoryMB >= 100 ? 0 : 1)))) MB", color: .purple)
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
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 8).fill(.quaternary.opacity(0.5)))
    }
}

private struct MetricPill: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Text(title)
                .foregroundStyle(.tertiary)
            Text(value)
                .foregroundStyle(color)
        }
        .font(.system(size: 10, weight: .medium, design: .rounded))
    }
}
