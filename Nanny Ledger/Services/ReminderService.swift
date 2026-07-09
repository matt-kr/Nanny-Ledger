//
//  ReminderService.swift
//  Nanny Ledger
//
//  Schedules the optional nightly "log your shift" reminder.
//

import Foundation
import UserNotifications

enum ReminderService {
    static let identifier = "nightly-log-reminder"

    /// Re-syncs the pending notification with the current settings.
    static func update(enabled: Bool, time: String) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        guard enabled else { return }

        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }

            let content = UNMutableNotificationContent()
            content.title = "Nanny Ledger"
            content.body = "Have care tonight? Log the shift with one tap. 🌙"
            content.sound = .default

            let parts = time.split(separator: ":").compactMap { Int($0) }
            var components = DateComponents()
            components.hour = parts.count > 0 ? parts[0] : 20
            components.minute = parts.count > 1 ? parts[1] : 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            center.add(request)
        }
    }
}
