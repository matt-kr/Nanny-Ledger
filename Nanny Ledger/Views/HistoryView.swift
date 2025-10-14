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
    
    let caregiver: Caregiver
    
    @State private var shiftToDelete: Shift?
    @State private var showingDeleteConfirmation = false
    
    private var settings: AppSettings? {
        settingsQuery.first
    }
    
    private var historicalShifts: [Shift] {
        guard let settings = settings else { return [] }
        let weekStart = Date().startOfWeek(weekStartDay: settings.weekStartDay)
        return allShifts.filter { 
            $0.date < weekStart && $0.caregiver?.id == caregiver.id
        }
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
                                settings: settings,
                                onDelete: { shift in
                                    shiftToDelete = shift
                                    showingDeleteConfirmation = true
                                }
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
            .alert("Delete Shift?", isPresented: $showingDeleteConfirmation, presenting: shiftToDelete) { shift in
                Button("Cancel", role: .cancel) {
                    shiftToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let shift = shiftToDelete {
                        modelContext.delete(shift)
                        try? modelContext.save()
                    }
                    shiftToDelete = nil
                }
            } message: { shift in
                Text("\(shift.date.formattedWithWeekday())\n\(shift.startTime) – \(shift.endTime)")
            }
        }
    }
}

struct WeekGroupView: View {
    let weekStart: Date
    let shifts: [Shift]
    let settings: AppSettings?
    let onDelete: (Shift) -> Void
    
    private var weekEnd: Date {
        Calendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
    }
    
    private var totalHours: Double {
        shifts.reduce(0.0) { $0 + $1.roundedHours }
    }
    
    private var totalAmount: Double {
        // Use caregiver's rate if available, otherwise fall back to settings
        let rate = shifts.first?.caregiver?.hourlyRate ?? settings?.hourlyRate ?? 35.0
        return totalHours * rate
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }
    
    private var zelleNote: String {
        NoteGenerator.generateZelleNote(shifts: shifts)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Week header
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Week of \(dateFormatter.string(from: weekStart)) - \(dateFormatter.string(from: weekEnd))")
                        .font(.headline)
                    
                    Text("\(shifts.count) \(shifts.count == 1 ? "night" : "nights") • \(String(format: "%.2f", totalHours))h • \(formatCurrency(totalAmount))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Payment Note
                if !shifts.isEmpty {
                    Divider()
                        .padding(.vertical, 4)
                    
                    VStack(spacing: 4) {
                        Text("Payment Note")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Button {
                            UIPasteboard.general.string = zelleNote
                        } label: {
                            Text(zelleNote)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.center)
                                .minimumScaleFactor(0.5)
                                .lineLimit(3)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(.tertiarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Shifts in this week
            ForEach(shifts) { shift in
                ShiftRowView(shift: shift, onDelete: {
                    onDelete(shift)
                })
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
    HistoryView(caregiver: Caregiver(name: "Maria", role: "Night Nanny"))
        .modelContainer(for: [Shift.self, AppSettings.self, Caregiver.self])
}
