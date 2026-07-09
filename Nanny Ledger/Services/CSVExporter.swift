//
//  CSVExporter.swift
//  Nanny Ledger
//
//  Generates a spreadsheet-ready export of shifts for tax records.
//

import Foundation

enum CSVExporter {

    static func csv(for shifts: [Shift], caregiver: Caregiver) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let weekdayFormatter = DateFormatter()
        weekdayFormatter.dateFormat = "EEEE"

        var rows: [String] = ["Date,Weekday,Start,End,Billed Hours,Hourly Rate,Amount,Paid,Caregiver"]

        for shift in shifts.sorted(by: { $0.date < $1.date }) {
            let rate = shift.caregiver?.hourlyRate ?? caregiver.hourlyRate
            let fields = [
                dateFormatter.string(from: shift.date),
                weekdayFormatter.string(from: shift.date),
                shift.startTime,
                shift.endTime,
                String(format: "%.2f", shift.roundedHours),
                String(format: "%.2f", rate),
                String(format: "%.2f", shift.earnings(at: rate)),
                shift.isPaid ? "Yes" : "No",
                escape(shift.caregiver?.name ?? caregiver.name),
            ]
            rows.append(fields.joined(separator: ","))
        }

        return rows.joined(separator: "\n")
    }

    /// Write CSV to a temp file and return its URL for sharing.
    static func writeTempFile(csv: String, filename: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    private static func escape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return field
    }
}
