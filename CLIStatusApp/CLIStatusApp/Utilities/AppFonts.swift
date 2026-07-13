import SwiftUI

extension Font {
    static let appCode = Font.system(size: 12, weight: .regular, design: .monospaced)
    static let appRowTitle = Font.system(size: 13, weight: .medium)
    static let appCaption = Font.system(size: 11)
    static let appMetric = Font.system(size: 10, weight: .medium, design: .rounded).monospacedDigit()
    static let appRank = Font.system(size: 11, weight: .semibold, design: .rounded).monospacedDigit()
    static let appHeroMetric = Font.system(size: 22, weight: .semibold, design: .rounded).monospacedDigit()
}
