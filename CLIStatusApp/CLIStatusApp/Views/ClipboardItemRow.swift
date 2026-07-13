import SwiftUI

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let onCopy: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        SurfaceRow {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: item.category.iconName)
                    .foregroundStyle(item.category.color)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(item.title)
                            .font(.appRowTitle)
                            .lineLimit(1)
                        Text(item.category.displayName)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, AppSpacing.xs)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(Color.primary.opacity(0.08)))
                    }
                    Text(item.contentPreview)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                Button { onCopy() } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("复制")
                .accessibilityLabel("复制")
            }
        }
        .contextMenu {
            Button { onCopy() } label: { Label("复制", systemImage: "doc.on.doc") }
            Button { onEdit() } label: { Label("编辑", systemImage: "pencil") }
            Divider()
            Button(role: .destructive) { onDelete() } label: { Label("删除", systemImage: "trash") }
        }
    }
}
