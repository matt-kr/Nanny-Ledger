//
//  Date+Helpers.swift
//  Nanny Ledger
//
//  Consolidated by assistant
//

import Foundation

public extension Date {
    var startOfDayLocal: Date { Calendar.current.startOfDay(for: self) }
}
