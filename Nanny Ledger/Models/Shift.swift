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
    @Attribute(.unique) var date: Date // Start of day for the night they arrived
    var startTime: String // HH:mm format (e.g., "22:00")
    var endTime: String   // HH:mm format (e.g., "08:00")
    var createdAt: Date
    var createdBy: String? // Optional: user identifier
    
    init(date: Date, startTime: String, endTime: String, createdBy: String? = nil) {
        self.date = Calendar.current.startOfDay(for: date)
        self.startTime = startTime
        self.endTime = endTime
        self.createdAt = Date()
        self.createdBy = createdBy
    }
    
    /// Calculate duration in hours (handles overnight shifts)
    var durationHours: Double {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let start = formatter.date(from: startTime),
              let end = formatter.date(from: endTime) else {
            return 0
        }
        
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: start)
        let endComponents = calendar.dateComponents([.hour, .minute], from: end)
        
        let startMinutes = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)
        var endMinutes = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)
        
        // If end is before start, it's an overnight shift
        if endMinutes <= startMinutes {
            endMinutes += 24 * 60
        }
        
        let durationMinutes = endMinutes - startMinutes
        return Double(durationMinutes) / 60.0
    }
    
    /// Round to nearest 0.25 hours for billing
    var roundedHours: Double {
        return (durationHours * 4).rounded() / 4
    }
}
