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
import SwiftData

// Default hours logic
struct DefaultHours {
    var weekdayStartEnd: [Int: (start: String, end: String)] // 1=Sun...7=Sat

    static let standard: DefaultHours = {
        var dict: [Int: (start: String, end: String)] = [:]
        for w in 1...7 { dict[w] = (start: "22:00", end: "08:00") } // 10pm–8am by default
        dict[6] = (start: "21:00", end: "07:00") // Friday night (weekday 6) → 9pm–7am
        return DefaultHours(weekdayStartEnd: dict)
    }()

    func startEnd(for date: Date) -> (start: String, end: String) {
        weekdayStartEnd[date.weekday] ?? (start: "22:00", end: "08:00")
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
struct ActivityShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

// MARK: - App
// NOTE: Demoted from @main to avoid multiple entry points
struct NightNannyLoggerApp: App {
    var body: some Scene {
        WindowGroup {
            MainContentView()
        }
        .modelContainer(for: [Shift.self, Caregiver.self, AppSettings.self])
    }
}
