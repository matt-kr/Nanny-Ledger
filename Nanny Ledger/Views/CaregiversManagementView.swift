//
//  CaregiversManagementView.swift
//  Nanny Ledger
//
//  Created by Matt Krussow on 10/13/25.
//

import SwiftUI
import SwiftData

struct CaregiversManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Caregiver.createdDate) private var caregivers: [Caregiver]
    
    @State private var editingCaregiver: Caregiver?
    @State private var showingAddCaregiver = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(caregivers) { caregiver in
                    Button {
                        editingCaregiver = caregiver
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(caregiver.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                if !caregiver.role.isEmpty && caregiver.role != caregiver.name {
                                    Text(caregiver.role)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack(spacing: 12) {
                                    Label(formatCurrency(caregiver.hourlyRate) + "/hr", systemImage: "dollarsign.circle")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Label("\(caregiver.defaultStartTime)–\(caregiver.defaultEndTime)", systemImage: "clock")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .onDelete(perform: deleteCaregivers)
            }
            .navigationTitle("Manage Caregivers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddCaregiver = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $editingCaregiver) { caregiver in
                CaregiverEditView(caregiver: caregiver)
            }
            .sheet(isPresented: $showingAddCaregiver) {
                CaregiverAddView()
            }
        }
    }
    
    private func deleteCaregivers(at offsets: IndexSet) {
        for index in offsets {
            let caregiver = caregivers[index]
            
            // Don't allow deleting if it's the only caregiver
            if caregivers.count <= 1 {
                return
            }
            
            modelContext.delete(caregiver)
        }
        
        try? modelContext.save()
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = .current
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
}

// MARK: - Add Caregiver View

struct CaregiverAddView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var role = ""
    @State private var hourlyRate = 35.0
    @State private var defaultStartTime = "22:00"
    @State private var defaultEndTime = "08:00"
    @State private var zelleInfo = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Name", text: $name)
                    TextField("Role (e.g., Night Nanny, Babysitter)", text: $role)
                }
                
                Section("Payment") {
                    HStack {
                        Text("Hourly Rate")
                        Spacer()
                        TextField("Rate", value: $hourlyRate, format: .currency(code: "USD"))
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                    
                    TextField("Zelle/Phone", text: $zelleInfo)
                        .keyboardType(.phonePad)
                }
                
                Section("Default Hours") {
                    HStack {
                        Text("Start Time")
                        Spacer()
                        TextField("HH:mm", text: $defaultStartTime)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numbersAndPunctuation)
                    }
                    
                    HStack {
                        Text("End Time")
                        Spacer()
                        TextField("HH:mm", text: $defaultEndTime)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numbersAndPunctuation)
                    }
                }
            }
            .navigationTitle("Add Caregiver")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addCaregiver()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func addCaregiver() {
        let caregiver = Caregiver(
            name: name,
            role: role,
            hourlyRate: hourlyRate,
            defaultStartTime: defaultStartTime,
            defaultEndTime: defaultEndTime,
            zelleInfo: zelleInfo
        )
        
        modelContext.insert(caregiver)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Edit Caregiver View

struct CaregiverEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var caregiver: Caregiver
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Name", text: $caregiver.name)
                    TextField("Role (e.g., Night Nanny, Babysitter)", text: $caregiver.role)
                }
                
                Section("Payment") {
                    HStack {
                        Text("Hourly Rate")
                        Spacer()
                        TextField("Rate", value: $caregiver.hourlyRate, format: .currency(code: "USD"))
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                    
                    TextField("Zelle/Phone", text: $caregiver.zelleInfo)
                        .keyboardType(.phonePad)
                }
                
                Section("Default Hours") {
                    HStack {
                        Text("Start Time")
                        Spacer()
                        TextField("HH:mm", text: $caregiver.defaultStartTime)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numbersAndPunctuation)
                    }
                    
                    HStack {
                        Text("End Time")
                        Spacer()
                        TextField("HH:mm", text: $caregiver.defaultEndTime)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numbersAndPunctuation)
                    }
                }
            }
            .navigationTitle("Edit Caregiver")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CaregiversManagementView()
        .modelContainer(for: [Caregiver.self])
}
