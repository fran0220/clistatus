import SwiftUI

struct SurfaceRow<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, AppSpacing.sm + 2)
            .padding(.vertical, AppSpacing.sm - 1)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.md)
                    .fill(Color.surfaceRow)
            )
    }
}
