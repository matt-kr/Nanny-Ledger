//
//  Caregiver.swift
//  Nanny Ledger
//
//  Created by Matt Krussow on 10/13/25.
//

import Foundation
import SwiftData

@Model
class Caregiver {
    var id: UUID = UUID()
    var name: String = ""
    var role: String = "Nanny" // "Night Nanny", "Day Nanny", "Babysitter", etc.
    var hourlyRate: Double = 35.0
    var defaultStartTime: String = "22:00"
    var defaultEndTime: String = "08:00"
    var zelleInfo: String = ""
    var isActive: Bool = true
    var createdDate: Date = Date()
    
    @Relationship(deleteRule: .cascade, inverse: \Shift.caregiver)
    var shifts: [Shift]?
    
    init(
        id: UUID = UUID(),
        name: String,
        role: String = "Nanny",
        hourlyRate: Double = 35.0,
        defaultStartTime: String = "22:00",
        defaultEndTime: String = "08:00",
        zelleInfo: String = "",
        isActive: Bool = true,
        createdDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.hourlyRate = hourlyRate
        self.defaultStartTime = defaultStartTime
        self.defaultEndTime = defaultEndTime
        self.zelleInfo = zelleInfo
        self.isActive = isActive
        self.createdDate = createdDate
    }
    
    var displayName: String {
        if role.isEmpty || role == name {
            return name
        }
        return "\(name) (\(role))"
    }
}
