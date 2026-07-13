import SwiftUI

struct ResourceCardView: View {
    let title: String
    let value: String
    let subtitle: String
    let systemImage: String
    let color: Color
    var progress: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs + 2) {
            HStack(spacing: 5) {
                Image(systemName: systemImage)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }

            Text(value)
                .font(.appHeroMetric)

            if let progress {
                UsageBarView(progress: progress / 100, color: color, height: 3)
            }

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
        .padding(AppSpacing.sm + 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.lg - 2)
                .fill(Color.surfaceRow)
        )
    }
}
