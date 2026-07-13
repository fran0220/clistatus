import SwiftUI

struct MetricPill: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Text(title)
                .foregroundStyle(.tertiary)
            Text(value)
                .foregroundStyle(color)
                .monospacedDigit()
        }
        .font(.appMetric)
    }
}
