import Foundation

enum CLITool: String, CaseIterable, Identifiable {
    case claudeCode = "claude"
    case codex = "codex"
    case geminiCLI = "gemini"
    case ampCode = "amp"
    case droid = "droid"
    case openCode = "opencode"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .claudeCode: return "Claude Code"
        case .codex: return "Codex"
        case .geminiCLI: return "Gemini CLI"
        case .ampCode: return "Amp Code"
        case .droid: return "Droid"
        case .openCode: return "OpenCode"
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
        case .openCode: return "opencode-ai"
        }
    }

    var updateCommand: [String] {
        switch self {
        case .ampCode:
            return ["amp", "update"]
        case .droid:
            return ["/bin/sh", "-c", "curl -fsSL https://app.factory.ai/cli | sh"]
        default:
            guard let pkg = npmPackage else { return [] }
            return ["npm", "update", "-g", pkg]
        }
    }

    var installCommand: [String] {
        switch self {
        case .ampCode:
            return ["/bin/sh", "-c", "curl -fsSL https://ampcode.com/install.sh | sh"]
        case .droid:
            return ["/bin/sh", "-c", "curl -fsSL https://app.factory.ai/cli | sh"]
        default:
            guard let pkg = npmPackage else { return [] }
            return ["npm", "install", "-g", pkg]
        }
    }

    var versionPattern: String {
        switch self {
        case .claudeCode: return #"(\d+\.\d+\.\d+)\s*\(Claude Code\)"#
        case .codex: return #"codex-cli\s+(\d+\.\d+\.\d+)"#
        case .ampCode: return #"^(\d+\.\d+\.\d+)"#
        default: return #"^(\d+\.\d+\.\d+)"#
        }
    }
}
