import SwiftUI

extension Color {
    static let brandPrimary = Color.accentColor

    static let statusSuccess = Color.green
    static let statusWarning = Color.orange
    static let statusError = Color.red
    static let statusInfo = Color.blue

    static let metricCPU = Color(red: 0.20, green: 0.55, blue: 0.90)
    static let metricMemory = Color(red: 0.18, green: 0.62, blue: 0.55)
    static let surfaceRow = Color.primary.opacity(0.06)
    static let rankMuted = Color.secondary.opacity(0.75)

    static let toolClaudeCode = Color(red: 0.9, green: 0.35, blue: 0.2)
    static let toolCodex = Color(red: 0.2, green: 0.6, blue: 0.9)
    static let toolGeminiCLI = Color(red: 0.3, green: 0.5, blue: 0.95)
    static let toolAmpCode = Color(red: 0.95, green: 0.5, blue: 0.2)
    static let toolDroid = Color(red: 0.5, green: 0.3, blue: 0.9)
}
