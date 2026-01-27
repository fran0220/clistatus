//
//  AppFonts.swift
//  CLIStatusApp
//
//  应用字体规范定义
//  定义标题字体、内容字体和代码字体
//

import SwiftUI

// MARK: - 标题字体

extension Font {
    /// 大标题字体 - 用于页面主标题
    /// 尺寸: 20pt, 权重: bold, 设计: rounded
    static let appLargeTitle = Font.system(size: 20, weight: .bold, design: .rounded)
    
    /// 标题字体 - 用于区域标题
    /// 尺寸: 16pt, 权重: semibold, 设计: rounded
    static let appTitle = Font.system(size: 16, weight: .semibold, design: .rounded)
    
    /// 二级标题字体 - 用于卡片标题
    /// 尺寸: 14pt, 权重: semibold, 设计: rounded
    static let appTitle2 = Font.system(size: 14, weight: .semibold, design: .rounded)
    
    /// 三级标题字体 - 用于分组标题
    /// 尺寸: 13pt, 权重: semibold, 设计: rounded
    static let appTitle3 = Font.system(size: 13, weight: .semibold, design: .rounded)
}

// MARK: - 内容字体

extension Font {
    /// 正文字体 - 用于主要内容
    /// 尺寸: 13pt, 权重: regular, 设计: rounded
    static let appBody = Font.system(size: 13, weight: .regular, design: .rounded)
    
    /// 强调正文字体 - 用于强调内容
    /// 尺寸: 13pt, 权重: medium, 设计: rounded
    static let appHeadline = Font.system(size: 13, weight: .medium, design: .rounded)
    
    /// 副标题字体 - 用于次要内容
    /// 尺寸: 12pt, 权重: regular, 设计: rounded
    static let appSubheadline = Font.system(size: 12, weight: .regular, design: .rounded)
    
    /// 项目标题字体 - 用于列表项名称
    /// 尺寸: 13pt, 权重: medium, 设计: rounded
    static let itemTitle = Font.system(size: 13, weight: .medium, design: .rounded)
    
    /// 项目副标题字体 - 用于列表项描述
    /// 尺寸: 11pt, 权重: regular, 设计: rounded
    static let itemSubtitle = Font.system(size: 11, weight: .regular, design: .rounded)
    
    /// 说明文字字体 - 用于辅助说明
    /// 尺寸: 10pt, 权重: medium, 设计: rounded
    static let appCaption = Font.system(size: 10, weight: .medium, design: .rounded)
    
    /// 小说明文字字体 - 用于时间戳等
    /// 尺寸: 9pt, 权重: regular, 设计: rounded
    static let appCaption2 = Font.system(size: 9, weight: .regular, design: .rounded)
}

// MARK: - 代码字体

extension Font {
    /// 代码字体 - 用于代码片段
    /// 尺寸: 12pt, 权重: regular, 设计: monospaced
    static let appCode = Font.system(size: 12, weight: .regular, design: .monospaced)
    
    /// 小代码字体 - 用于版本号等
    /// 尺寸: 11pt, 权重: regular, 设计: monospaced
    static let appCodeSmall = Font.system(size: 11, weight: .regular, design: .monospaced)
    
    /// 版本号字体 - 专用于版本号显示
    /// 尺寸: 11pt, 权重: semibold, 设计: monospaced
    static let version = Font.system(size: 11, weight: .semibold, design: .monospaced)
}

// MARK: - 字体辅助扩展

extension View {
    /// 应用标题样式
    func appTitleStyle() -> some View {
        self.font(.appTitle)
            .foregroundStyle(Color.textPrimary)
    }
    
    /// 应用正文样式
    func appBodyStyle() -> some View {
        self.font(.appBody)
            .foregroundStyle(Color.textPrimary)
    }
    
    /// 应用次要文字样式
    func appSecondaryStyle() -> some View {
        self.font(.appSubheadline)
            .foregroundStyle(Color.textSecondary)
    }
    
    /// 应用说明文字样式
    func appCaptionStyle() -> some View {
        self.font(.appCaption)
            .foregroundStyle(Color.textTertiary)
    }
    
    /// 应用代码样式
    func appCodeStyle() -> some View {
        self.font(.appCode)
            .foregroundStyle(Color.textPrimary)
    }
    
    /// 应用版本号样式
    func versionStyle() -> some View {
        self.font(.version)
            .foregroundStyle(Color.textSecondary)
    }
}
