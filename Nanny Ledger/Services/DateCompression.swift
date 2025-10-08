//
//  DateCompression.swift
//  Nanny Ledger
//
//  Created by Matt Krussow on 10/8/25.
//

import Foundation

struct DateRun {
    let start: Date
    let end: Date
}

struct DateCompression {
    
    /// Compress dates into consecutive runs
    static func compressDates(_ dates: [Date]) -> [DateRun] {
        let calendar = Calendar.current
        let uniqueDates = Array(Set(dates.map { calendar.startOfDay(for: $0) })).sorted()
        
        guard !uniqueDates.isEmpty else { return [] }
        
        var runs: [DateRun] = []
        var runStart = uniqueDates[0]
        var prev = uniqueDates[0]
        
        for date in uniqueDates.dropFirst() {
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: prev),
               calendar.isDate(date, inSameDayAs: nextDay) {
                prev = date
            } else {
                runs.append(DateRun(start: runStart, end: prev))
                runStart = date
                prev = date
            }
        }
        
        runs.append(DateRun(start: runStart, end: prev))
        return runs
    }
    
    /// Format runs into readable string: "Oct 5–9, 11, 14–15"
    static func formatRuns(_ runs: [DateRun]) -> String {
        guard !runs.isEmpty else { return "" }
        
        let monthDayFormatter: DateFormatter = {
            let f = DateFormatter()
            f.locale = .current
            f.setLocalizedDateFormatFromTemplate("MMM d")
            return f
        }()
        
        let dayOnlyFormatter: DateFormatter = {
            let f = DateFormatter()
            f.locale = .current
            f.setLocalizedDateFormatFromTemplate("d")
            return f
        }()
        
        let fullFormatter: DateFormatter = {
            let f = DateFormatter()
            f.locale = .current
            f.dateStyle = .medium
            return f
        }()
        
        let calendar = Calendar.current
        
        func sameMonthYear(_ a: Date, _ b: Date) -> Bool {
            let compA = calendar.dateComponents([.year, .month], from: a)
            let compB = calendar.dateComponents([.year, .month], from: b)
            return compA.year == compB.year && compA.month == compB.month
        }
        
        var parts: [String] = []
        
        for run in runs {
            if calendar.isDate(run.start, inSameDayAs: run.end) {
                // Single day
                parts.append(monthDayFormatter.string(from: run.start))
            } else if sameMonthYear(run.start, run.end) {
                // Same month: "Oct 5–9"
                parts.append("\(monthDayFormatter.string(from: run.start))–\(dayOnlyFormatter.string(from: run.end))")
            } else {
                // Cross month/year: "Oct 30 – Nov 2"
                parts.append("\(monthDayFormatter.string(from: run.start)) – \(monthDayFormatter.string(from: run.end))")
            }
        }
        
        return parts.joined(separator: ", ")
    }
}
