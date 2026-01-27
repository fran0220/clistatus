import Foundation
import SwiftUI
import AppKit

enum CLITool: String, CaseIterable, Identifiable {
    case claudeCode = "claude"
    case codex = "codex"
    case geminiCLI = "gemini"
    case ampCode = "amp"
    case droid = "droid"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .claudeCode: return "Claude Code"
        case .codex: return "Codex"
        case .geminiCLI: return "Gemini CLI"
        case .ampCode: return "Amp Code"
        case .droid: return "Droid"
        }
    }
    
    // MARK: - 图标属性
    
    /// 工具专属 SF Symbol 图标名称
    var iconName: String {
        switch self {
        case .claudeCode: return "sparkles"           // Claude AI 特色 - 星火图标
        case .codex: return "brain.head.profile"      // OpenAI 脑形图标
        case .geminiCLI: return "diamond.fill"        // Google Gemini 钻石图标
        case .ampCode: return "bolt.fill"             // Amp = 快速闪电
        case .droid: return "cpu.fill"                // Droid = 机器人 CPU
        }
    }

    /// 工具专属图标资源名（Resources/ToolIcons 下的文件名，不含扩展名）
    var iconAssetName: String {
        switch self {
        case .claudeCode: return "claude"
        case .codex: return "codex"
        case .geminiCLI: return "gemini"
        case .ampCode: return "amp"
        case .droid: return "droid"
        }
    }

    /// 尝试从资源包加载官方图标（png/pdf/jpg），加载失败返回 nil
    var officialIconImage: Image? {
        let extensions = ["pdf", "png", "jpg", "jpeg"]
        let names = ["ToolIcons/\(iconAssetName)", iconAssetName]
        for ext in extensions {
            for name in names {
                if let url = Bundle.module.url(forResource: name, withExtension: ext),
                   let nsImage = NSImage(contentsOf: url) {
                    return Image(nsImage: nsImage)
                }
            }
        }
        return nil
    }
    
    /// 工具专属品牌颜色
    var iconColor: Color {
        switch self {
        case .claudeCode: return .toolClaudeCode      // 橙红色
        case .codex: return .toolCodex                // 蓝色
        case .geminiCLI: return .toolGeminiCLI        // 蓝紫色
        case .ampCode: return .toolAmpCode            // 橙色
        case .droid: return .toolDroid                // 紫色
        }
    }
    
    /// 工具描述
    var toolDescription: String {
        switch self {
        case .claudeCode: return "Anthropic Claude AI 编程助手"
        case .codex: return "OpenAI Codex 代码生成工具"
        case .geminiCLI: return "Google Gemini 命令行工具"
        case .ampCode: return "Sourcegraph 代码搜索与智能助手"
        case .droid: return "Factory AI 开发助手"
        }
    }

    var versionCommand: [String] {
        [rawValue, "--version"]
    }

    var npmPackage: String? {
        switch self {
        case .claudeCode: return "@anthropic-ai/claude-code"
        case .codex: return "@openai/codex"
        case .geminiCLI: return "@google/gemini-cli"
        case .ampCode: return "@sourcegraph/amp"
        case .droid: return nil
        }
    }

    var updateCommand: [String] {
        switch self {
        case .claudeCode:
            return ["claude", "update"]
        case .geminiCLI:
            return ["npm", "install", "-g", "@google/gemini-cli@latest"]
        case .ampCode:
            return ["amp", "update"]
        case .codex:
            return ["npm", "install", "-g", "@openai/codex@latest"]
        case .droid:
            return ["/bin/sh", "-c", "curl -fsSL https://app.factory.ai/cli | sh"]
        }
    }

    var installCommand: [String] {
        switch self {
        case .claudeCode:
            return ["npm", "install", "-g", "@anthropic-ai/claude-code"]
        case .ampCode:
            return ["/bin/sh", "-c", "curl -fsSL https://ampcode.com/install.sh | sh"]
        case .droid:
            return ["/bin/sh", "-c", "curl -fsSL https://app.factory.ai/cli | sh"]
        case .codex, .geminiCLI:
            guard let pkg = npmPackage else { return [] }
            return ["npm", "install", "-g", pkg]
        }
    }

    var versionPattern: String {
        switch self {
        case .claudeCode: return #"(\d+\.\d+\.\d+)\s*\(Claude Code\)"#
        case .codex: return #"codex-cli\s+(\d+\.\d+\.\d+)"#
        case .ampCode: return #"^(\d+\.\d+\.\d+)"#
        default: return #"(\d+\.\d+\.\d+)"#
        }
    }
}
