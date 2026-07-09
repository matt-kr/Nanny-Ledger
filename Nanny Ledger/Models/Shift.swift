//
//  Shift.swift
//  Nanny Ledger
//
//  Created by Matt Krussow on 10/8/25.
//

import Foundation
import SwiftData

@Model
final class Shift {
    var date: Date = Date() // Start of day for the night they arrived (removed .unique for CloudKit)
    var startTime: String = "22:00" // HH:mm format (e.g., "22:00")
    var endTime: String = "08:00"   // HH:mm format (e.g., "08:00")
    var isPaid: Bool = false
    var createdAt: Date = Date()
    var createdBy: String? // Optional: user identifier
    var caregiver: Caregiver?

    init(date: Date, startTime: String, endTime: String, caregiver: Caregiver? = nil, createdBy: String? = nil) {
        self.date = Calendar.current.startOfDay(for: date)
        self.startTime = startTime
        self.endTime = endTime
        self.isPaid = false
        self.caregiver = caregiver
        self.createdAt = Date()
        self.createdBy = createdBy
    }

    /// Calculate duration in hours (handles overnight shifts)
    var durationHours: Double {
        TimeUtil.durationHours(start: startTime, end: endTime)
    }

    /// Round to nearest 0.25 hours for billing
    var roundedHours: Double {
        (durationHours * 4).rounded() / 4
    }

    /// "10:00 PM – 8:00 AM"
    var timeRangeDisplay: String {
        "\(TimeUtil.display(startTime)) – \(TimeUtil.display(endTime))"
    }

    func earnings(at rate: Double) -> Double {
        roundedHours * rate
    }
}
