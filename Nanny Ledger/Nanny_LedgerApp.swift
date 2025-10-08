//
//  Nanny_LedgerApp.swift
//  Nanny Ledger
//
//  Created by Matt Krussow on 10/8/25.
//

import SwiftUI
import UniformTypeIdentifiers
import UIKit
import Combine

// MARK: - Model
struct Shift: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date // treat as local start-of-day (the night of)
    var startTime: String // e.g., "21:00"
    var endTime: String   // e.g., "07:00"
}

// MARK: - Persistence
final class ShiftStore: ObservableObject {
    @Published var shifts: [Shift] = [] {
        didSet { save() }
    }

    private let fileURL: URL

    init() {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = docs.appendingPathComponent("nanny_shifts.json")
        load()
    }

    func load() {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([Shift].self, from: data)
            self.shifts = decoded
        } catch {
            self.shifts = []
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(shifts)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Save error: \(error)")
        }
    }
}

// MARK: - Helpers
extension Date {
    var startOfDayLocal: Date { Calendar.current.startOfDay(for: self) }
    func addingDays(_ d: Int) -> Date { Calendar.current.date(byAdding: .day, value: d, to: self)! }
    var weekday: Int { Calendar.current.component(.weekday, from: self) } // 1=Sun ... 7=Sat
}

struct DateRun: Hashable { let start: Date; let end: Date }

/// Compress an array of Dates (start-of-day) into human-friendly ranges like "Oct 5–9, 11, 14–15".
func compressDates(_ dates: [Date]) -> [DateRun] {
    let days = Array(Set(dates.map { $0.startOfDayLocal })).sorted()
    guard !days.isEmpty else { return [] }
    var runs: [DateRun] = []
    var runStart = days[0]
    var prev = days[0]
    for d in days.dropFirst() {
        let nextDay = prev.addingDays(1).startOfDayLocal
        if d == nextDay {
            prev = d
            continue
        } else {
            runs.append(DateRun(start: runStart, end: prev))
            runStart = d
            prev = d
        }
    }
    runs.append(DateRun(start: runStart, end: prev))
    return runs
}

func formatRuns(_ runs: [DateRun]) -> String {
    guard !runs.isEmpty else { return "" }
    let monthDay: DateFormatter = {
        let f = DateFormatter()
        f.locale = .current
        f.setLocalizedDateFormatFromTemplate("MMM d")
        return f
    }()
    let dayOnly: DateFormatter = {
        let f = DateFormatter()
        f.locale = .current
        f.setLocalizedDateFormatFromTemplate("d")
        return f
    }()
    let full: DateFormatter = {
        let f = DateFormatter()
        f.locale = .current
        f.dateStyle = .medium
        return f
    }()

    func sameMonthYear(_ a: Date, _ b: Date) -> Bool {
        let cal = Calendar.current
        let ca = cal.dateComponents([.year, .month], from: a)
        let cb = cal.dateComponents([.year, .month], from: b)
        return ca.year == cb.year && ca.month == cb.month
    }

    var parts: [String] = []
    for r in runs {
        if r.start == r.end {
            parts.append(monthDay.string(from: r.start))
        } else if sameMonthYear(r.start, r.end) {
            parts.append("\(monthDay.string(from: r.start))–\(dayOnly.string(from: r.end))")
        } else {
            // spans months/years
            parts.append("\(full.string(from: r.start))–\(full.string(from: r.end))")
        }
    }
    return parts.joined(separator: ", ")
}

// Default hours logic
struct DefaultHours {
    var weekdayStartEnd: [Int: (String, String)] // 1=Sun...7=Sat

    static let standard: DefaultHours = {
        var dict: [Int: (String, String)] = [:]
        for w in 1...7 { dict[w] = ("22:00", "08:00") } // 10pm–8am by default
        dict[6] = ("21:00", "07:00") // Friday night (weekday 6) → 9pm–7am
        return DefaultHours(weekdayStartEnd: dict)
    }()

    func startEnd(for date: Date) -> (String, String) {
        weekdayStartEnd[date.weekday] ?? ("22:00", "08:00")
    }
}

// Week handling
func startOfWeek(for date: Date, weekStartsOn: Int) -> Date { // weekStartsOn: 1=Sun..7=Sat
    var d = date.startOfDayLocal
    while d.weekday != weekStartsOn { d = d.addingDays(-1) }
    return d
}

func endOfWeekUpToToday(for date: Date) -> Date { date.startOfDayLocal }

func defaultStart() -> String { "22:00" }
func defaultEnd() -> String { "08:00" }

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

// MARK: - App
@main
struct NightNannyLoggerApp: App {
    @StateObject private var store = ShiftStore()
    var body: some Scene {
        WindowGroup { ContentView().environmentObject(store) }
    }
}
