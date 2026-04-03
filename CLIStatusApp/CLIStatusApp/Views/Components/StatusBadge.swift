import SwiftUI

enum StatusType: Equatable {
    case success, warning, error, loading, info, installed, notInstalled, updateAvailable

    var color: Color {
        switch self {
        case .success, .installed: return .green
        case .warning, .updateAvailable: return .orange
        case .error, .notInstalled: return .red
        case .loading: return .gray
        case .info: return .blue
        }
    }
}

struct StatusBadge: View {
    let type: StatusType
    let text: String?

    init(type: StatusType, text: String? = nil) {
        self.type = type
        self.text = text
    }

    var body: some View {
        Text(text ?? defaultText)
            .font(.caption2)
            .foregroundStyle(type.color)
    }

    private var defaultText: String {
        switch type {
        case .success: return "成功"
        case .warning: return "警告"
        case .error: return "错误"
        case .loading: return "检查中"
        case .info: return "信息"
        case .installed: return "已安装"
        case .updateAvailable: return "有更新"
        case .notInstalled: return "未安装"
        }
    }
}
