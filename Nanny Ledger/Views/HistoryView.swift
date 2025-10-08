//
//  HistoryView.swift
//  Nanny Ledger
//
//  Created by Matt Krussow on 10/8/25.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Shift.date, order: .reverse) private var allShifts: [Shift]
    @Query private var settingsQuery: [AppSettings]
    
    private var settings: AppSettings? {
        settingsQuery.first
    }
    
    private var historicalShifts: [Shift] {
        guard let settings = settings else { return [] }
        let weekStart = Date().startOfWeek(weekStartDay: settings.weekStartDay)
        return allShifts.filter { $0.date < weekStart }
    }
    
    private var groupedShifts: [(weekStart: Date, shifts: [Shift])] {
        guard let settings = settings else { return [] }
        
        var groups: [Date: [Shift]] = [:]
        
        for shift in historicalShifts {
            let weekStart = shift.date.startOfWeek(weekStartDay: settings.weekStartDay)
            if groups[weekStart] == nil {
                groups[weekStart] = []
            }
            groups[weekStart]?.append(shift)
        }
        
        return groups.map { (weekStart: $0.key, shifts: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.weekStart > $1.weekStart }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if historicalShifts.isEmpty {
                        Text("No historical shifts")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                    } else {
                        ForEach(groupedShifts, id: \.weekStart) { group in
                            WeekGroupView(
                                weekStart: group.weekStart,
                                shifts: group.shifts,
                                settings: settings
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Shift History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct WeekGroupView: View {
    let weekStart: Date
    let shifts: [Shift]
    let settings: AppSettings?
    
    private var weekEnd: Date {
        Calendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
    }
    
    private var totalHours: Double {
        shifts.reduce(0.0) { $0 + $1.roundedHours }
    }
    
    private var totalAmount: Double {
        totalHours * (settings?.hourlyRate ?? 35.0)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Week header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Week of \(dateFormatter.string(from: weekStart)) - \(dateFormatter.string(from: weekEnd))")
                        .font(.headline)
                    
                    Text("\(shifts.count) \(shifts.count == 1 ? "night" : "nights") • \(String(format: "%.2f", totalHours))h • \(formatCurrency(totalAmount))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Shifts in this week
            ForEach(shifts) { shift in
                ShiftRowView(shift: shift)
            }
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = .current
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [Shift.self, AppSettings.self])
}
