//
//  Date+Extensions.swift
//  Nanny Ledger
//
//  Created by Matt Krussow on 10/8/25.
//

import Foundation

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    func startOfWeek(weekStartDay: Int = 1) -> Date {
        let calendar = Calendar.current
        let date = self.startOfDay
        let currentWeekday = calendar.component(.weekday, from: date)
        
        var daysToSubtract = currentWeekday - weekStartDay
        if daysToSubtract < 0 {
            daysToSubtract += 7
        }
        
        return calendar.date(byAdding: .day, value: -daysToSubtract, to: date) ?? date
    }
    
    func addingDays(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
    
    var weekday: Int {
        Calendar.current.component(.weekday, from: self)
    }
    
    func formattedShort() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: self)
    }
    
    func formattedMedium() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }
}
