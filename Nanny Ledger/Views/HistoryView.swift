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
    @State private var shiftToEdit: Shift?

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

    private var allTimeHours: Double {
        historicalShifts.reduce(0.0) { $0 + $1.roundedHours }
    }

    private var allTimeAmount: Double {
        historicalShifts.reduce(0.0) { $0 + $1.earnings(at: caregiver.hourlyRate) }
    }

    private var groupedShifts: [(weekStart: Date, shifts: [Shift])] {
        guard let settings = settings else { return [] }

        var groups: [Date: [Shift]] = [:]

        for shift in historicalShifts {
            let weekStart = shift.date.startOfWeek(weekStartDay: settings.weekStartDay)
            groups[weekStart, default: []].append(shift)
        }

        return groups.map { (weekStart: $0.key, shifts: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.weekStart > $1.weekStart }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if historicalShifts.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.title)
                                .foregroundStyle(.tertiary)
                            Text("No historical shifts")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else {
                        allTimeSummary

                        ForEach(groupedShifts, id: \.weekStart) { group in
                            WeekGroupView(
                                weekStart: group.weekStart,
                                shifts: group.shifts,
                                rate: caregiver.hourlyRate,
                                onDelete: { shift in
                                    shiftToDelete = shift
                                    showingDeleteConfirmation = true
                                },
                                onEdit: { shift in
                                    shiftToEdit = shift
                                },
                                onTogglePaid: { shift in
                                    shift.isPaid.toggle()
                                    try? modelContext.save()
                                    Haptics.tap()
                                },
                                onMarkWeekPaid: { shifts in
                                    for shift in shifts where !shift.isPaid {
                                        shift.isPaid = true
                                    }
                                    try? modelContext.save()
                                    Haptics.success()
                                }
                            )
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("\(caregiver.name)'s History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $shiftToEdit) { shift in
                EditShiftView(shift: shift)
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
                Text("\(shift.date.formattedWithWeekday())\n\(shift.timeRangeDisplay)")
            }
        }
    }

    private var allTimeSummary: some View {
        HStack(spacing: 0) {
            summaryStat(value: "\(historicalShifts.count)", label: historicalShifts.count == 1 ? "night" : "nights")
            summaryDivider
            summaryStat(value: allTimeHours.hoursString, label: "hours")
            summaryDivider
            summaryStat(value: allTimeAmount.currencyString, label: "earned")
        }
        .foregroundStyle(.white)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Theme.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var summaryDivider: some View {
        Rectangle()
            .fill(.white.opacity(0.25))
            .frame(width: 1, height: 32)
    }

    private func summaryStat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(label)
                .font(.caption2)
                .opacity(0.85)
        }
        .frame(maxWidth: .infinity)
    }
}

struct WeekGroupView: View {
    let weekStart: Date
    let shifts: [Shift]
    let rate: Double
    let onDelete: (Shift) -> Void
    var onEdit: ((Shift) -> Void)? = nil
    var onTogglePaid: ((Shift) -> Void)? = nil
    var onMarkWeekPaid: (([Shift]) -> Void)? = nil

    @State private var copiedNote = false

    private var weekEnd: Date {
        Calendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
    }

    private var totalHours: Double {
        shifts.reduce(0.0) { $0 + $1.roundedHours }
    }

    private var totalAmount: Double {
        totalHours * rate
    }

    private var allPaid: Bool {
        shifts.allSatisfy { $0.isPaid }
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
        VStack(spacing: 8) {
            // Week header
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(dateFormatter.string(from: weekStart)) – \(dateFormatter.string(from: weekEnd))")
                            .font(.headline)

                        Text("\(shifts.count) \(shifts.count == 1 ? "night" : "nights") · \(totalHours.hoursString)h · \(totalAmount.currencyString)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if allPaid {
                        Label("Paid", systemImage: "checkmark.seal.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.green.opacity(0.12))
                            .clipShape(Capsule())
                    } else if let onMarkWeekPaid {
                        Button {
                            onMarkWeekPaid(shifts)
                        } label: {
                            Label("Mark Paid", systemImage: "checkmark.seal")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Theme.accent)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Theme.accent.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                }

                // Payment note with copy feedback
                Button {
                    UIPasteboard.general.string = zelleNote
                    Haptics.tap()
                    withAnimation { copiedNote = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { copiedNote = false }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: copiedNote ? "checkmark" : "doc.on.doc")
                            .font(.caption)
                        Text(copiedNote ? "Copied!" : zelleNote)
                            .font(.caption)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    .foregroundStyle(copiedNote ? Color.green : .secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            // Shifts in this week
            ForEach(shifts) { shift in
                ShiftRowView(
                    shift: shift,
                    rate: rate,
                    onDelete: { onDelete(shift) },
                    onTap: onEdit.map { edit in { edit(shift) } },
                    onTogglePaid: onTogglePaid.map { toggle in { toggle(shift) } }
                )
            }
        }
    }
}

#Preview {
    HistoryView(caregiver: Caregiver(name: "Maria", role: "Night Nanny"))
        .modelContainer(for: [Shift.self, AppSettings.self, Caregiver.self])
}
