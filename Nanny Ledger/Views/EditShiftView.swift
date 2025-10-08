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
    
    @State private var startTime: String
    @State private var endTime: String
    @State private var showingError = false
    @State private var errorMessage = ""
    
    init(shift: Shift) {
        self.shift = shift
        _startTime = State(initialValue: shift.startTime)
        _endTime = State(initialValue: shift.endTime)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Night Date") {
                    HStack {
                        Text("Date")
                        Spacer()
                        Text(shift.date.formattedWithWeekday())
                            .foregroundStyle(.secondary)
                    }
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
            .navigationTitle("Edit Night")
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
    
    private func saveChanges() {
        // Validate time format
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard formatter.date(from: startTime) != nil,
              formatter.date(from: endTime) != nil else {
            errorMessage = "Please use HH:mm format (e.g., 22:00)"
            showingError = true
            return
        }
        
        // Update the shift
        shift.startTime = startTime
        shift.endTime = endTime
        
        try? modelContext.save()
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
