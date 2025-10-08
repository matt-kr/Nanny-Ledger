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
    
    @State private var selectedDate = Date()
    @State private var startTime = "22:00"
    @State private var endTime = "08:00"
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Night Date") {
                    DatePicker(
                        "Date",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                }
                
                Section("Hours") {
                    HStack {
                        Text("Start Time")
                        Spacer()
                        TextField("HH:mm", text: $startTime)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numbersAndPunctuation)
                    }
                    
                    HStack {
                        Text("End Time")
                        Spacer()
                        TextField("HH:mm", text: $endTime)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numbersAndPunctuation)
                    }
                }
                
                Section {
                    Text("Duration: \(calculatedDuration)")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Night")
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
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var calculatedDuration: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let start = formatter.date(from: startTime),
              let end = formatter.date(from: endTime) else {
            return "Invalid time format"
        }
        
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: start)
        let endComponents = calendar.dateComponents([.hour, .minute], from: end)
        
        let startMinutes = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)
        var endMinutes = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)
        
        if endMinutes <= startMinutes {
            endMinutes += 24 * 60
        }
        
        let durationMinutes = endMinutes - startMinutes
        let hours = Double(durationMinutes) / 60.0
        
        return String(format: "~%.2f hours", hours)
    }
    
    private func addShift() {
        // Validate time format
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard formatter.date(from: startTime) != nil,
              formatter.date(from: endTime) != nil else {
            errorMessage = "Please use HH:mm format (e.g., 22:00)"
            showingError = true
            return
        }
        
        // Check for duplicate date
        let calendar = Calendar.current
        let shiftDate = calendar.startOfDay(for: selectedDate)
        
        let descriptor = FetchDescriptor<Shift>(
            predicate: #Predicate { shift in
                shift.date == shiftDate
            }
        )
        
        if let existing = try? modelContext.fetch(descriptor), !existing.isEmpty {
            errorMessage = "A shift already exists for this date"
            showingError = true
            return
        }
        
        let shift = Shift(
            date: selectedDate,
            startTime: startTime,
            endTime: endTime
        )
        
        modelContext.insert(shift)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    AddShiftView()
        .modelContainer(for: [Shift.self])
}
