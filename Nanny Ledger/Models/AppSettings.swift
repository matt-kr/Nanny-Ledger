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
    var weekStartDay: Int = 1 // 1 = Sunday, 2 = Monday, etc.
    var hourlyRate: Double = 35.0
    var appendTotalsToNote: Bool = true
    
    // Recipient info for payments (optional for migration compatibility)
    var recipientName: String = "Maria"
    var recipientPhone: String = ""
    
    // Color scheme: 0=system, 1=light, 2=dark
    var colorScheme: Int = 0
    
    // Last selected caregiver ID
    var lastSelectedCaregiverId: UUID?
    
    // Receipt client information (persistent)
    var receiptClientName: String = ""
    var receiptClientPhone: String = ""
    var receiptClientEmail: String = ""
    var receiptClientAddress: String = ""
    
    // Receipt provider information (persistent)
    var receiptProviderEmail: String = ""
    var receiptProviderAddress: String = ""
    var receiptProviderTaxId: String = ""
    var receiptServiceProvided: String = "Childcare Services"
    
    // Default hours for each weekday (1=Sun...7=Sat)
    var sundayStart: String = "22:00"
    var sundayEnd: String = "08:00"
    var mondayStart: String = "22:00"
    var mondayEnd: String = "08:00"
    var tuesdayStart: String = "22:00"
    var tuesdayEnd: String = "08:00"
    var wednesdayStart: String = "22:00"
    var wednesdayEnd: String = "08:00"
    var thursdayStart: String = "22:00"
    var thursdayEnd: String = "08:00"
    var fridayStart: String = "21:00"
    var fridayEnd: String = "07:00"
    var saturdayStart: String = "22:00"
    var saturdayEnd: String = "08:00"
    
    init() {
        self.weekStartDay = 1 // Sunday
        self.hourlyRate = 35.0
        self.appendTotalsToNote = true
        self.recipientName = "Maria"
        self.recipientPhone = ""
        self.colorScheme = 0 // System default
        
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
