import SwiftUI

enum StatusType: Equatable {
    case success, warning, error, loading, info, installed, notInstalled, updateAvailable

    var color: Color {
        switch self {
        case .success, .installed: return .statusSuccess
        case .warning, .updateAvailable: return .statusWarning
        case .error, .notInstalled: return .statusError
        case .loading: return .secondary
        case .info: return .statusInfo
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
            .fontWeight(.medium)
            .foregroundStyle(type.color)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(Capsule().fill(type.color.opacity(0.12)))
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
