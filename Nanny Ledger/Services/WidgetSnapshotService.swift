//
//  WidgetSnapshotService.swift
//  Nanny Ledger
//
//  Writes a lightweight JSON snapshot of the current week to the
//  shared app group so the widget can display it without touching
//  SwiftData or CloudKit.
//

import Foundation
import SwiftData
import WidgetKit

/// Mirror of the struct in the widget target — keep the two in sync.
struct WidgetWeekSnapshot: Codable {
    var caregiverName: String
    var nights: Int
    var hours: Double
    var totalDue: Double
    var todayLogged: Bool
    var updatedAt: Date

    static let appGroupID = "group.com.mattkrussow.Nanny-Ledger"
    static let filename = "week-snapshot.json"
}

enum WidgetSnapshotService {

    /// Recomputes the week snapshot from the store and hands it to the widget.
    static func refresh(modelContext: ModelContext) {
        guard let settings = try? modelContext.fetch(FetchDescriptor<AppSettings>()).first else { return }

        let caregivers = (try? modelContext.fetch(
            FetchDescriptor<Caregiver>(sortBy: [SortDescriptor(\.createdDate)])
        )) ?? []
        guard let caregiver = caregivers.first(where: { $0.id == settings.lastSelectedCaregiverId }) ?? caregivers.first else { return }

        let allShifts = (try? modelContext.fetch(FetchDescriptor<Shift>())) ?? []
        let weekStart = Date().startOfWeek(weekStartDay: settings.weekStartDay)
        let weekShifts = allShifts.filter { $0.caregiver?.id == caregiver.id && $0.date >= weekStart }

        let hours = weekShifts.reduce(0.0) { $0 + $1.roundedHours }
        let todayStart = Calendar.current.startOfDay(for: Date())

        let snapshot = WidgetWeekSnapshot(
            caregiverName: caregiver.name,
            nights: weekShifts.count,
            hours: hours,
            totalDue: hours * caregiver.hourlyRate,
            todayLogged: weekShifts.contains { $0.date == todayStart },
            updatedAt: Date()
        )

        guard let url = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: WidgetWeekSnapshot.appGroupID)?
            .appendingPathComponent(WidgetWeekSnapshot.filename),
            let data = try? JSONEncoder().encode(snapshot) else { return }

        try? data.write(to: url, options: .atomic)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
