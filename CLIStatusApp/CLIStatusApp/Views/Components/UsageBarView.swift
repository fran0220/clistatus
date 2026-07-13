import SwiftUI

struct UsageBarView: View {
    let progress: Double
    let color: Color
    var height: CGFloat = 4

    private var clamped: Double {
        min(1, max(0, progress))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.08))

                Capsule()
                    .fill(color)
                    .frame(width: max(height, geo.size.width * clamped))
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}
