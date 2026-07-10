//
//  AddShiftView.swift
//  Nanny Ledger
//
//  Created by Matt Krussow on 10/8/25.
//

import SwiftUI
import SwiftData

struct AddShiftView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Caregiver.createdDate) private var allCaregivers: [Caregiver]

    @State private var selectedCaregiver: Caregiver
    @State private var selectedDate = Date()
    @State private var startTime: String
    @State private var endTime: String
    @State private var showingError = false
    @State private var errorMessage = ""

    init(defaultCaregiver: Caregiver) {
        _selectedCaregiver = State(initialValue: defaultCaregiver)
        _startTime = State(initialValue: defaultCaregiver.defaultStartTime)
        _endTime = State(initialValue: defaultCaregiver.defaultEndTime)
    }

    var body: some View {
        NavigationStack {
            Form {
                if allCaregivers.count > 1 {
                    Section("Caregiver") {
                        Picker("Caregiver", selection: $selectedCaregiver) {
                            ForEach(allCaregivers, id: \.id) { caregiver in
                                Text(caregiver.displayName).tag(caregiver)
                            }
                        }
                        .onChange(of: selectedCaregiver) { _, newValue in
                            if !newValue.defaultStartTime.isEmpty {
                                startTime = newValue.defaultStartTime
                                endTime = newValue.defaultEndTime
                            }
                        }
                    }
                }

                Section("Date") {
                    DatePicker(
                        "Date",
                        selection: $selectedDate,
                        in: ...Date().addingDays(1),
                        displayedComponents: .date
                    )
                }

                Section("Hours") {
                    TimeField(label: "Start Time", time: $startTime)
                    TimeField(label: "End Time", time: $endTime)
                }

                Section {
                    HStack {
                        Text("Duration")
                        Spacer()
                        Text("\(TimeUtil.durationHours(start: startTime, end: endTime).hoursString) hours")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Amount")
                        Spacer()
                        Text(estimatedAmount.currencyString)
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    Text("Overnight shifts (ending after midnight) are calculated automatically.")
                }
            }
            .navigationTitle("Add Shift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addShift()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var estimatedAmount: Double {
        let hours = TimeUtil.durationHours(start: startTime, end: endTime)
        let rounded = (hours * 4).rounded() / 4
        return rounded * selectedCaregiver.hourlyRate
    }

    private func addShift() {
        let calendar = Calendar.current
        let shiftDate = calendar.startOfDay(for: selectedDate)

        // Only block duplicates for the same caregiver on the same date
        let descriptor = FetchDescriptor<Shift>(
            predicate: #Predicate { shift in
                shift.date == shiftDate
            }
        )

        if let existing = try? modelContext.fetch(descriptor),
           existing.contains(where: { $0.caregiver?.id == selectedCaregiver.id }) {
            errorMessage = "A shift for \(selectedCaregiver.name) already exists on this date. You can edit it from the home screen."
            showingError = true
            return
        }

        let shift = Shift(
            date: selectedDate,
            startTime: startTime,
            endTime: endTime,
            caregiver: selectedCaregiver
        )

        modelContext.insert(shift)
        try? modelContext.save()
        WidgetSnapshotService.refresh(modelContext: modelContext)
        Haptics.success()
        dismiss()
    }
}

#Preview {
    AddShiftView(defaultCaregiver: Caregiver(name: "Maria", role: "Night Nanny"))
        .modelContainer(for: [Shift.self, Caregiver.self])
}
