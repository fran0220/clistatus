//
//  AppColors.swift
//  CLIStatusApp
//
//  应用颜色系统定义
//  定义品牌色、语义化状态色、背景层级色和文字颜色
//

import SwiftUI

// MARK: - 品牌色

extension Color {
    /// 主品牌色 - 深蓝色调，符合开发者工具审美
    static let brandPrimary = Color(red: 0.25, green: 0.47, blue: 0.89)    // #4073E3
    
    /// 次品牌色 - 冷青色调，用于渐变效果
    static let brandSecondary = Color(red: 0.18, green: 0.73, blue: 0.78)  // #2EBAC7
    
    /// 品牌渐变 - 用于强调元素
    static let brandGradient = LinearGradient(
        colors: [.brandPrimary, .brandSecondary],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - 语义化状态色

extension Color {
    /// 成功状态色 - 柔和的绿色
    static let statusSuccess = Color(red: 0.20, green: 0.70, blue: 0.40)   // #33B366
    
    /// 警告状态色 - 橙色
    static let statusWarning = Color(red: 0.95, green: 0.60, blue: 0.15)   // #F29926
    
    /// 错误状态色 - 红色
    static let statusError = Color(red: 0.90, green: 0.25, blue: 0.30)     // #E6404D
    
    /// 信息状态色 - 蓝色
    static let statusInfo = Color(red: 0.25, green: 0.55, blue: 0.90)      // #408CE6
    
    /// 检查中状态色 - 灰色
    static let statusChecking = Color(red: 0.60, green: 0.60, blue: 0.65)  // #9999A6
}

// MARK: - 状态背景色（带透明度）

extension Color {
    /// 成功状态背景色
    static let bgSuccess = statusSuccess.opacity(0.08)
    
    /// 警告状态背景色
    static let bgWarning = statusWarning.opacity(0.08)
    
    /// 错误状态背景色
    static let bgError = statusError.opacity(0.08)
    
    /// 信息状态背景色
    static let bgInfo = statusInfo.opacity(0.08)
}

// MARK: - 背景层级色

extension Color {
    /// 主背景色 - 控件背景
    static let surfacePrimary = Color(nsColor: .controlBackgroundColor)
    
    /// 次背景色 - 二级填充
    static let surfaceSecondary = Color(nsColor: .secondarySystemFill)
    
    /// 三级背景色 - 三级填充
    static let surfaceTertiary = Color(nsColor: .tertiarySystemFill)
    
    /// 分组背景色 - 用于卡片等容器
    static let surfaceGrouped = Color(nsColor: .windowBackgroundColor)
    
    /// 边框颜色
    static let border = Color(nsColor: .separatorColor)
    
    /// 分割线颜色
    static let divider = Color(nsColor: .separatorColor)
}

// MARK: - 文字颜色

extension Color {
    /// 主文字颜色
    static let textPrimary = Color(nsColor: .labelColor)
    
    /// 次文字颜色
    static let textSecondary = Color(nsColor: .secondaryLabelColor)
    
    /// 三级文字颜色
    static let textTertiary = Color(nsColor: .tertiaryLabelColor)
    
    /// 占位符文字颜色
    static let textPlaceholder = Color(nsColor: .placeholderTextColor)
}

// MARK: - 工具专属颜色

extension Color {
    /// Claude Code 品牌色 - 橙红色
    static let toolClaudeCode = Color(red: 0.9, green: 0.35, blue: 0.2)    // #E65933
    
    /// Codex 品牌色 - 蓝色
    static let toolCodex = Color(red: 0.2, green: 0.6, blue: 0.9)          // #3399E6
    
    /// Gemini CLI 品牌色 - 蓝紫色
    static let toolGeminiCLI = Color(red: 0.3, green: 0.5, blue: 0.95)     // #4D80F2
    
    /// Amp Code 品牌色 - 橙色
    static let toolAmpCode = Color(red: 0.95, green: 0.5, blue: 0.2)       // #F28033
    
    /// Droid 品牌色 - 紫色
    static let toolDroid = Color(red: 0.5, green: 0.3, blue: 0.9)          // #804DE6
    
    /// NPM 品牌色 - 红色
    static let npmRed = Color(red: 0.8, green: 0.2, blue: 0.2)             // #CC3333

    /// Homebrew 品牌色 - 琥珀色
    static let brewAmber = Color(red: 0.85, green: 0.55, blue: 0.15)       // #D98C26
}

// MARK: - 颜色辅助方法

extension Color {
    /// 创建带透明度的状态背景色
    /// - Parameters:
    ///   - color: 基础颜色
    ///   - opacity: 透明度，默认 0.08
    /// - Returns: 带透明度的颜色
    static func statusBackground(_ color: Color, opacity: Double = 0.08) -> Color {
        color.opacity(opacity)
    }
}
