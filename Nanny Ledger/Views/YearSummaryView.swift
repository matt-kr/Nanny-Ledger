//
//  YearSummaryView.swift
//  Nanny Ledger
//
//  Year-at-a-glance totals with quarterly breakdown and CSV export
//  for tax season (dependent-care FSA, Form 2441, household employment).
//

import SwiftUI
import SwiftData

struct YearSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Shift.date, order: .reverse) private var allShifts: [Shift]

    let caregiver: Caregiver

    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var shareItem: ShareItem?

    private var caregiverShifts: [Shift] {
        allShifts.filter { $0.caregiver?.id == caregiver.id }
    }

    private var availableYears: [Int] {
        let years = Set(caregiverShifts.map { Calendar.current.component(.year, from: $0.date) })
        return years.sorted(by: >)
    }

    private var yearShifts: [Shift] {
        caregiverShifts.filter { Calendar.current.component(.year, from: $0.date) == selectedYear }
    }

    private func quarterShifts(_ quarter: Int) -> [Shift] {
        yearShifts.filter {
            let month = Calendar.current.component(.month, from: $0.date)
            return (month - 1) / 3 + 1 == quarter
        }
    }

    private var totalHours: Double {
        yearShifts.reduce(0.0) { $0 + $1.roundedHours }
    }

    private var totalAmount: Double {
        yearShifts.reduce(0.0) { $0 + $1.earnings(at: caregiver.hourlyRate) }
    }

    private var unpaidAmount: Double {
        yearShifts.filter { !$0.isPaid }.reduce(0.0) { $0 + $1.earnings(at: caregiver.hourlyRate) }
    }

    var body: some View {
        NavigationStack {
            List {
                if availableYears.count > 1 {
                    Section {
                        Picker("Year", selection: $selectedYear) {
                            ForEach(availableYears, id: \.self) { year in
                                Text(String(year)).tag(year)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                Section("\(String(selectedYear)) Totals") {
                    row("Nights", "\(yearShifts.count)")
                    row("Hours", totalHours.hoursString)
                    row("Total", totalAmount.currencyString, emphasized: true)
                    if unpaidAmount > 0 {
                        HStack {
                            Text("Still unpaid")
                            Spacer()
                            Text(unpaidAmount.currencyString)
                                .foregroundStyle(.orange)
                                .fontWeight(.medium)
                        }
                    }
                }

                Section("Quarterly Breakdown") {
                    ForEach(1...4, id: \.self) { quarter in
                        let shifts = quarterShifts(quarter)
                        let hours = shifts.reduce(0.0) { $0 + $1.roundedHours }
                        let amount = shifts.reduce(0.0) { $0 + $1.earnings(at: caregiver.hourlyRate) }

                        HStack {
                            Text("Q\(quarter)")
                                .fontWeight(.semibold)
                                .frame(width: 36, alignment: .leading)
                            Text("\(shifts.count) \(shifts.count == 1 ? "night" : "nights") · \(hours.hoursString)h")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                            Spacer()
                            Text(amount.currencyString)
                                .fontWeight(.medium)
                        }
                    }
                }

                Section {
                    Button {
                        exportCSV()
                    } label: {
                        Label("Export \(String(selectedYear)) as CSV", systemImage: "square.and.arrow.up")
                            .fontWeight(.medium)
                    }
                    .disabled(yearShifts.isEmpty)
                } footer: {
                    Text("Includes every shift with dates, hours, rate, amount, and paid status — ready for a spreadsheet or your tax preparer. Amounts use \(caregiver.name)'s current hourly rate.")
                }
            }
            .navigationTitle("Year Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $shareItem) { item in
                ShareSheet(items: item.activityItems)
            }
        }
    }

    private func row(_ label: String, _ value: String, emphasized: Bool = false) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .fontWeight(emphasized ? .semibold : .regular)
                .foregroundStyle(emphasized ? Color.primary : Color.secondary)
        }
    }

    private func exportCSV() {
        let csv = CSVExporter.csv(for: yearShifts, caregiver: caregiver)
        let safeName = caregiver.name.replacingOccurrences(of: " ", with: "_")
        if let url = CSVExporter.writeTempFile(csv: csv, filename: "NannyLedger_\(safeName)_\(selectedYear).csv") {
            shareItem = ShareItem(url: url)
            Haptics.tap()
        }
    }
}

#Preview {
    YearSummaryView(caregiver: Caregiver(name: "Maria", role: "Night Nanny"))
        .modelContainer(for: [Shift.self, Caregiver.self])
}
