//
//  Date+Helpers.swift
//  Nanny Ledger
//
//  Consolidated by assistant
//

import Foundation

public extension Date {
    var startOfDayLocal: Date { Calendar.current.startOfDay(for: self) }
    func addingDays(_ d: Int) -> Date { Calendar.current.date(byAdding: .day, value: d, to: self)! }
    var weekday: Int { Calendar.current.component(.weekday, from: self) } // 1=Sun ... 7=Sat
}
