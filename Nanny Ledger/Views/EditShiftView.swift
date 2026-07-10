//
//  EditShiftView.swift
//  Nanny Ledger
//
//  Created by Matt Krussow on 10/8/25.
//

import SwiftUI
import SwiftData

struct EditShiftView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var shift: Shift

    @State private var selectedDate: Date
    @State private var startTime: String
    @State private var endTime: String
    @State private var isPaid: Bool

    init(shift: Shift) {
        self.shift = shift
        _selectedDate = State(initialValue: shift.date)
        _startTime = State(initialValue: shift.startTime)
        _endTime = State(initialValue: shift.endTime)
        _isPaid = State(initialValue: shift.isPaid)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Date") {
                    DatePicker(
                        "Date",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                }

                Section("Hours") {
                    TimeField(label: "Start Time", time: $startTime)
                    TimeField(label: "End Time", time: $endTime)
                }

                Section("Payment") {
                    Toggle("Paid", isOn: $isPaid)
                        .tint(.purple)
                }

                Section {
                    HStack {
                        Text("Duration")
                        Spacer()
                        Text("\(TimeUtil.durationHours(start: startTime, end: endTime).hoursString) hours")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Shift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveChanges() {
        shift.date = Calendar.current.startOfDay(for: selectedDate)
        shift.startTime = startTime
        shift.endTime = endTime
        shift.isPaid = isPaid

        try? modelContext.save()
        WidgetSnapshotService.refresh(modelContext: modelContext)
        Haptics.success()
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Shift.self, configurations: config)
    let shift = Shift(date: Date(), startTime: "22:00", endTime: "08:00")
    container.mainContext.insert(shift)

    return EditShiftView(shift: shift)
        .modelContainer(container)
}
