//
//  NoteGenerator.swift
//  Nanny Ledger
//
//  Created by Matt Krussow on 10/8/25.
//

import Foundation

struct NoteGenerator {
    
    /// Generate Zelle-ready payment note: "Sun 5 Oct, Mon 6 Oct, Tue 7 Oct"
    static func generateZelleNote(shifts: [Shift]) -> String {
        guard !shifts.isEmpty else { return "No shifts this week" }
        
        let sortedShifts = shifts.sorted { $0.date < $1.date }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d MMM" // "Sun 5 Oct"
        
        let dateStrings = sortedShifts.map { formatter.string(from: $0.date) }
        return dateStrings.joined(separator: ", ")
    }
    
    /// Generate Week-to-Date note
    static func generateWeekNote(shifts: [Shift], rate: Double, appendTotals: Bool) -> String {
        guard !shifts.isEmpty else { return "No shifts logged this week" }
        
        let dates = shifts.map { $0.date }
        let runs = DateCompression.compressDates(dates)
        let datesString = DateCompression.formatRuns(runs)
        
        // Check if all shifts have same hours
        let uniformHours: Bool = {
            guard let first = shifts.first else { return false }
            return shifts.allSatisfy { $0.startTime == first.startTime && $0.endTime == first.endTime }
        }()
        
        var note = "Night nanny dates: \(datesString)"
        
        if uniformHours, let first = shifts.first {
            note += " (\(first.startTime)–\(first.endTime))"
        }
        
        if appendTotals {
            let nightCount = shifts.count
            let totalHours = shifts.reduce(0.0) { $0 + $1.roundedHours }
            let totalAmount = totalHours * rate
            
            note += " — \(nightCount) \(nightCount == 1 ? "night" : "nights"), ~\(String(format: "%.2f", totalHours))h, \(formatCurrency(totalAmount))"
        }
        
        return note
    }
    
    /// Generate full note (all time)
    static func generateFullNote(shifts: [Shift], rate: Double) -> String {
        guard !shifts.isEmpty else { return "No shifts logged" }
        
        let dates = shifts.map { $0.date }
        let runs = DateCompression.compressDates(dates)
        let datesString = DateCompression.formatRuns(runs)
        
        let nightCount = shifts.count
        let totalHours = shifts.reduce(0.0) { $0 + $1.roundedHours }
        let totalAmount = totalHours * rate
        
        return "Night nanny dates: \(datesString) — \(nightCount) \(nightCount == 1 ? "night" : "nights"), ~\(String(format: "%.2f", totalHours))h, \(formatCurrency(totalAmount))"
    }
    
    private static func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = .current
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
}
