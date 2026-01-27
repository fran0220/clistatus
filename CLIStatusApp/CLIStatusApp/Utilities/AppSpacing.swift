//
//  AppSpacing.swift
//  CLIStatusApp
//
//  应用间距规范定义
//  定义 xs/sm/md/lg/xl 五级间距和圆角规范
//

import SwiftUI

// MARK: - 间距规范

/// 应用统一间距规范
/// 使用五级间距系统确保视觉一致性
enum AppSpacing {
    /// 超小间距 - 4pt
    /// 用于紧凑元素间隙，如图标与文字
    static let xs: CGFloat = 4
    
    /// 小间距 - 8pt
    /// 用于相关元素之间，如按钮内边距
    static let sm: CGFloat = 8
    
    /// 中间距 - 12pt
    /// 用于组内元素之间，如列表项内部
    static let md: CGFloat = 12
    
    /// 大间距 - 16pt
    /// 用于卡片内边距，主要区域间隙
    static let lg: CGFloat = 16
    
    /// 超大间距 - 20pt
    /// 用于页面边距，大区域分割
    static let xl: CGFloat = 20
    
    /// 超超大间距 - 24pt
    /// 用于主要区块之间
    static let xxl: CGFloat = 24
}

// MARK: - 圆角规范

/// 应用统一圆角规范
enum AppCornerRadius {
    /// 小圆角 - 4pt
    /// 用于小按钮、标签等
    static let xs: CGFloat = 4
    
    /// 小圆角 - 6pt
    /// 用于按钮、输入框等
    static let sm: CGFloat = 6
    
    /// 中圆角 - 8pt
    /// 用于卡片、弹窗等
    static let md: CGFloat = 8
    
    /// 大圆角 - 12pt
    /// 用于大卡片、模态框等
    static let lg: CGFloat = 12
    
    /// 圆形 - 用于圆形按钮、头像等
    static let full: CGFloat = 9999
}

// MARK: - 尺寸规范

/// 应用统一尺寸规范
enum AppSize {
    /// 图标尺寸
    enum Icon {
        /// 小图标 - 12pt
        static let sm: CGFloat = 12
        
        /// 中图标 - 16pt
        static let md: CGFloat = 16
        
        /// 大图标 - 20pt
        static let lg: CGFloat = 20
        
        /// 超大图标 - 24pt
        static let xl: CGFloat = 24
        
        /// 工具图标容器 - 36pt
        static let toolContainer: CGFloat = 36
    }
    
    /// 按钮尺寸
    enum Button {
        /// 小按钮高度 - 24pt
        static let heightSm: CGFloat = 24
        
        /// 中按钮高度 - 32pt
        static let heightMd: CGFloat = 32
        
        /// 大按钮高度 - 40pt
        static let heightLg: CGFloat = 40
    }
    
    /// 列表项高度
    enum ListItem {
        /// 紧凑列表项 - 44pt
        static let compact: CGFloat = 44
        
        /// 标准列表项 - 56pt
        static let standard: CGFloat = 56
        
        /// 扩展列表项 - 72pt
        static let expanded: CGFloat = 72
    }
    
    /// 卡片尺寸
    enum Card {
        /// 最小宽度 - 280pt
        static let minWidth: CGFloat = 280
        
        /// 标准宽度 - 340pt
        static let standardWidth: CGFloat = 340
        
        /// 最大宽度 - 400pt
        static let maxWidth: CGFloat = 400
    }
}

// MARK: - 阴影规范

/// 应用统一阴影规范
enum AppShadow {
    /// 小阴影 - 用于悬浮按钮等
    static let sm = Shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
    
    /// 中阴影 - 用于卡片等
    static let md = Shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 4)
    
    /// 大阴影 - 用于弹窗等
    static let lg = Shadow(color: Color.black.opacity(0.18), radius: 18, x: 0, y: 8)
}

/// 阴影数据结构
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - View 扩展

extension View {
    /// 应用小阴影
    func shadowSm() -> some View {
        self.shadow(
            color: AppShadow.sm.color,
            radius: AppShadow.sm.radius,
            x: AppShadow.sm.x,
            y: AppShadow.sm.y
        )
    }
    
    /// 应用中阴影
    func shadowMd() -> some View {
        self.shadow(
            color: AppShadow.md.color,
            radius: AppShadow.md.radius,
            x: AppShadow.md.x,
            y: AppShadow.md.y
        )
    }
    
    /// 应用大阴影
    func shadowLg() -> some View {
        self.shadow(
            color: AppShadow.lg.color,
            radius: AppShadow.lg.radius,
            x: AppShadow.lg.x,
            y: AppShadow.lg.y
        )
    }
    
    /// 标准卡片内边距
    func cardPadding() -> some View {
        self.padding(AppSpacing.lg)
    }
    
    /// 列表项内边距
    func listItemPadding() -> some View {
        self.padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
    }
    
    /// 区域内边距
    func sectionPadding() -> some View {
        self.padding(AppSpacing.md)
    }
}
