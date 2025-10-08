//
//  AppSettings.swift
//  Nanny Ledger
//
//  Created by Matt Krussow on 10/8/25.
//

import Foundation
import SwiftData

@Model
final class AppSettings {
    var weekStartDay: Int // 1 = Sunday, 2 = Monday, etc.
    var hourlyRate: Double
    var appendTotalsToNote: Bool
    
    // Default hours for each weekday (1=Sun...7=Sat)
    var sundayStart: String
    var sundayEnd: String
    var mondayStart: String
    var mondayEnd: String
    var tuesdayStart: String
    var tuesdayEnd: String
    var wednesdayStart: String
    var wednesdayEnd: String
    var thursdayStart: String
    var thursdayEnd: String
    var fridayStart: String
    var fridayEnd: String
    var saturdayStart: String
    var saturdayEnd: String
    
    init() {
        self.weekStartDay = 1 // Sunday
        self.hourlyRate = 35.0
        self.appendTotalsToNote = true
        
        // Default: Sun-Thu, Sat = 22:00-08:00, Fri = 21:00-07:00
        self.sundayStart = "22:00"
        self.sundayEnd = "08:00"
        self.mondayStart = "22:00"
        self.mondayEnd = "08:00"
        self.tuesdayStart = "22:00"
        self.tuesdayEnd = "08:00"
        self.wednesdayStart = "22:00"
        self.wednesdayEnd = "08:00"
        self.thursdayStart = "22:00"
        self.thursdayEnd = "08:00"
        self.fridayStart = "21:00"
        self.fridayEnd = "07:00"
        self.saturdayStart = "22:00"
        self.saturdayEnd = "08:00"
    }
    
    func defaultTimes(for date: Date) -> (start: String, end: String) {
        let weekday = Calendar.current.component(.weekday, from: date)
        switch weekday {
        case 1: return (sundayStart, sundayEnd)
        case 2: return (mondayStart, mondayEnd)
        case 3: return (tuesdayStart, tuesdayEnd)
        case 4: return (wednesdayStart, wednesdayEnd)
        case 5: return (thursdayStart, thursdayEnd)
        case 6: return (fridayStart, fridayEnd)
        case 7: return (saturdayStart, saturdayEnd)
        default: return ("22:00", "08:00")
        }
    }
}
