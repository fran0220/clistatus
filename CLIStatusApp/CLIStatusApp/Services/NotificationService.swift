import Foundation
import UserNotifications

@MainActor
final class NotificationService {
    static let shared = NotificationService()

    private var isAvailable = false

    private init() {}

    func requestAuthorization() async {
        // UNUserNotificationCenter requires a proper app bundle
        guard Bundle.main.bundleIdentifier != nil else {
            print("Notifications unavailable: no bundle identifier")
            isAvailable = false
            return
        }

        do {
            try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
            isAvailable = true
        } catch {
            print("Notification authorization failed: \(error)")
            isAvailable = false
        }
    }

    func sendUpdateComplete(tool: CLITool, newVersion: VersionInfo) {
        guard isAvailable else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(tool.displayName) Updated"
        content.body = "Successfully updated to v\(newVersion.display)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    func sendInstallComplete(tool: CLITool, version: VersionInfo) {
        guard isAvailable else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(tool.displayName) Installed"
        content.body = "Successfully installed v\(version.display)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    func sendError(tool: CLITool, message: String) {
        guard isAvailable else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(tool.displayName) Error"
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
