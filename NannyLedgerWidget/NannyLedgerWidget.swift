//
//  NannyLedgerWidget.swift
//  NannyLedgerWidget
//
//  Home-screen widget showing this week's totals. The app writes a
//  JSON snapshot to the shared app group; the widget only reads it —
//  no SwiftData or CloudKit in this process. Tapping deep-links into
//  the app to log tonight's shift.
//

import WidgetKit
import SwiftUI

// MARK: - Shared snapshot (mirror of the struct in the app target)

struct WidgetWeekSnapshot: Codable {
    var caregiverName: String
    var nights: Int
    var hours: Double
    var totalDue: Double
    var todayLogged: Bool
    var updatedAt: Date

    static let appGroupID = "group.com.mattkrussow.Nanny-Ledger"
    static let filename = "week-snapshot.json"

    static func load() -> WidgetWeekSnapshot? {
        guard let url = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(filename),
            let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(WidgetWeekSnapshot.self, from: data)
    }

    static let sample = WidgetWeekSnapshot(
        caregiverName: "Maria",
        nights: 4,
        hours: 40,
        totalDue: 1400,
        todayLogged: false,
        updatedAt: Date()
    )
}

// MARK: - Timeline

struct WeekEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetWeekSnapshot?
}

struct WeekProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeekEntry {
        WeekEntry(date: Date(), snapshot: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (WeekEntry) -> Void) {
        completion(WeekEntry(date: Date(), snapshot: WidgetWeekSnapshot.load() ?? .sample))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeekEntry>) -> Void) {
        let entry = WeekEntry(date: Date(), snapshot: WidgetWeekSnapshot.load())
        // Refresh at the next midnight so "tonight" state stays correct;
        // the app also reloads timelines whenever data changes.
        let midnight = Calendar.current.startOfDay(for: Date()).addingTimeInterval(86400)
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }
}

// MARK: - Views

struct WeekWidgetView: View {
    var entry: WeekEntry
    @Environment(\.widgetFamily) private var family

    private let gradient = LinearGradient(
        colors: [.blue, .purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        Group {
            if let snapshot = entry.snapshot {
                switch family {
                case .systemMedium:
                    mediumView(snapshot)
                default:
                    smallView(snapshot)
                }
            } else {
                emptyView
            }
        }
        .containerBackground(for: .widget) {
            gradient
        }
        .widgetURL(URL(string: "nannyledger://log-today"))
    }

    private func smallView(_ snapshot: WidgetWeekSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "moon.stars.fill")
                    .font(.caption)
                Text("This Week")
                    .font(.caption.weight(.semibold))
            }
            .opacity(0.9)

            Spacer(minLength: 2)

            Text(currency(snapshot.totalDue))
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text("\(snapshot.nights) \(snapshot.nights == 1 ? "night" : "nights") · \(hoursString(snapshot.hours))h")
                .font(.caption2)
                .opacity(0.9)

            Spacer(minLength: 2)

            statusFooter(snapshot)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func mediumView(_ snapshot: WidgetWeekSnapshot) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "moon.stars.fill")
                    Text("This Week · \(snapshot.caregiverName)")
                }
                .font(.caption.weight(.semibold))
                .opacity(0.9)

                Text(currency(snapshot.totalDue))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                statusFooter(snapshot)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                mediumStat(value: "\(snapshot.nights)", label: snapshot.nights == 1 ? "night" : "nights")
                mediumStat(value: hoursString(snapshot.hours), label: "hours")
            }
        }
        .foregroundStyle(.white)
    }

    private func mediumStat(value: String, label: String) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
            Text(label)
                .font(.caption2)
                .opacity(0.85)
        }
    }

    private func statusFooter(_ snapshot: WidgetWeekSnapshot) -> some View {
        HStack(spacing: 4) {
            Image(systemName: snapshot.todayLogged ? "checkmark.circle.fill" : "plus.circle.fill")
                .font(.caption2)
            Text(snapshot.todayLogged ? "Logged today" : "Tap to log today")
                .font(.caption2.weight(.medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.white.opacity(0.2))
        .clipShape(Capsule())
    }

    private var emptyView: some View {
        VStack(spacing: 6) {
            Image(systemName: "moon.stars.fill")
                .font(.title3)
            Text("Open Nanny Ledger to get started")
                .font(.caption2)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.white)
    }

    private func currency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = amount.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }

    private func hoursString(_ hours: Double) -> String {
        let formatted = String(format: "%.2f", hours)
        if formatted.hasSuffix(".00") { return String(formatted.dropLast(3)) }
        if formatted.hasSuffix("0") { return String(formatted.dropLast(1)) }
        return formatted
    }
}

// MARK: - Widget

struct WeekSummaryWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WeekSummaryWidget", provider: WeekProvider()) { entry in
            WeekWidgetView(entry: entry)
        }
        .configurationDisplayName("This Week")
        .description("Week totals at a glance, with one-tap logging.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct NannyLedgerWidgetBundle: WidgetBundle {
    var body: some Widget {
        WeekSummaryWidget()
    }
}
