//
//  Theme.swift
//  Nanny Ledger
//
//  Shared styling, formatting, and haptics helpers.
//

import SwiftUI
import UIKit

// MARK: - Brand

enum Theme {
    /// The app's signature blue → purple gradient.
    static let gradient = LinearGradient(
        colors: [.blue, .purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accent = Color.purple
}

// MARK: - Card style

struct CardBackground: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

extension View {
    func cardStyle(padding: CGFloat = 16) -> some View {
        modifier(CardBackground(padding: padding))
    }
}

// MARK: - Formatting

extension Double {
    /// "$350.00" in the user's locale.
    var currencyString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = .current
        return formatter.string(from: NSNumber(value: self)) ?? String(format: "$%.2f", self)
    }

    /// Hours with trailing zeros trimmed: 10.0 → "10", 10.25 → "10.25"
    var hoursString: String {
        let formatted = String(format: "%.2f", self)
        if formatted.hasSuffix(".00") {
            return String(formatted.dropLast(3))
        }
        if formatted.hasSuffix("0") {
            return String(formatted.dropLast(1))
        }
        return formatted
    }
}

// MARK: - Time helpers ("HH:mm" storage format)

enum TimeUtil {
    private static let storageFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        f.locale = .current
        return f
    }()

    static func date(from hhmm: String) -> Date? {
        storageFormatter.date(from: hhmm)
    }

    static func hhmm(from date: Date) -> String {
        storageFormatter.string(from: date)
    }

    /// "22:00" → "10:00 PM" (locale-aware)
    static func display(_ hhmm: String) -> String {
        guard let date = date(from: hhmm) else { return hhmm }
        return displayFormatter.string(from: date)
    }

    /// Duration in hours between two "HH:mm" times, rolling over midnight if needed.
    static func durationHours(start: String, end: String) -> Double {
        guard let startDate = date(from: start), let endDate = date(from: end) else { return 0 }
        let calendar = Calendar.current
        let s = calendar.dateComponents([.hour, .minute], from: startDate)
        let e = calendar.dateComponents([.hour, .minute], from: endDate)

        let startMinutes = (s.hour ?? 0) * 60 + (s.minute ?? 0)
        var endMinutes = (e.hour ?? 0) * 60 + (e.minute ?? 0)
        if endMinutes <= startMinutes {
            endMinutes += 24 * 60 // overnight shift
        }
        return Double(endMinutes - startMinutes) / 60.0
    }
}

// MARK: - Reusable time picker bound to "HH:mm" strings

struct TimeField: View {
    let label: String
    @Binding var time: String

    var body: some View {
        DatePicker(
            label,
            selection: Binding(
                get: { TimeUtil.date(from: time) ?? TimeUtil.date(from: "22:00")! },
                set: { time = TimeUtil.hhmm(from: $0) }
            ),
            displayedComponents: .hourAndMinute
        )
    }
}

// MARK: - Haptics

enum Haptics {
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
