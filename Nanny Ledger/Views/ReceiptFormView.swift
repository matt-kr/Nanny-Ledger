//
//  ReceiptFormView.swift
//  Nanny Ledger
//
//  Created by Matt Krussow on 10/13/25.
//

import SwiftUI

struct ReceiptFormView: View {
    @Environment(\.dismiss) private var dismiss
    
    let shifts: [Shift]
    let caregiver: Caregiver
    
    // Receipt Details
    @State private var receiptTitle: String = "Childcare Receipt"
    @State private var receiptNumber: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var notes: String = ""
    
    // Provider Information
    @State private var providerName: String
    @State private var providerRole: String
    @State private var providerPhone: String
    @State private var providerEmail: String = ""
    @State private var providerAddress: String = ""
    @State private var providerTaxId: String = ""
    @State private var serviceProvided: String = ""
    
    // Client Information
    @State private var clientName: String = ""
    @State private var clientAddress: String = ""
    @State private var clientPhone: String = ""
    @State private var clientEmail: String = ""
    
    // Toggles
    @State private var includeSignatureLine: Bool = true
    @State private var includeClientSignature: Bool = true
    @State private var includeAddress: Bool = false
    @State private var includeTaxId: Bool = false
    @State private var includeEmail: Bool = false
    
    @State private var shareItem: ShareItem?
    
    init(shifts: [Shift], caregiver: Caregiver) {
        self.shifts = shifts
        self.caregiver = caregiver
        
        // Initialize with caregiver defaults
        _providerName = State(initialValue: caregiver.name)
        _providerRole = State(initialValue: caregiver.role)
        _providerPhone = State(initialValue: caregiver.zelleInfo)
        _receiptNumber = State(initialValue: "NL-\(Int(Date().timeIntervalSince1970))")
        
        // Initialize date range from shifts
        let sortedShifts = shifts.sorted { $0.date < $1.date }
        _startDate = State(initialValue: sortedShifts.first?.date ?? Date())
        _endDate = State(initialValue: sortedShifts.last?.date ?? Date())
        _serviceProvided = State(initialValue: "Childcare Services")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Receipt Details Section (moved to top)
                Section {
                    TextField("Receipt Title", text: $receiptTitle)
                    TextField("Receipt Number", text: $receiptNumber)
                    
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    
                    Toggle("Include Provider Signature Line", isOn: $includeSignatureLine)
                    Toggle("Include Client Signature Line", isOn: $includeClientSignature)
                    
                    TextField("Additional Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Receipt Details")
                } footer: {
                    Text("Notes will appear at the bottom of the receipt")
                }
                
                // Provider Section
                Section {
                    TextField("Name", text: $providerName)
                    TextField("Role/Title", text: $providerRole)
                    TextField("Service Provided", text: $serviceProvided)
                    TextField("Phone", text: $providerPhone)
                        .keyboardType(.phonePad)
                    
                    Toggle("Include Email", isOn: $includeEmail)
                    if includeEmail {
                        TextField("Email", text: $providerEmail)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                    }
                    
                    Toggle("Include Address", isOn: $includeAddress)
                    if includeAddress {
                        TextField("Address", text: $providerAddress, axis: .vertical)
                            .lineLimit(2...4)
                    }
                    
                    Toggle("Include SSN / EIN", isOn: $includeTaxId)
                    if includeTaxId {
                        TextField("SSN / EIN (optional)", text: $providerTaxId)
                    }
                } header: {
                    Text("Service Provider Information")
                }
                
                // Client Section
                Section {
                    TextField("Client Name", text: $clientName)
                    TextField("Phone (optional)", text: $clientPhone)
                        .keyboardType(.phonePad)
                    TextField("Email (optional)", text: $clientEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    TextField("Address (optional)", text: $clientAddress, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Client Information")
                }
                
                // Summary Section
                Section {
                    let totalHours = shifts.reduce(0.0) { $0 + $1.roundedHours }
                    let totalAmount = totalHours * caregiver.hourlyRate
                    
                    HStack {
                        Text("Shifts")
                        Spacer()
                        Text("\(shifts.count)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Total Hours")
                        Spacer()
                        Text(String(format: "%.2f", totalHours))
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Hourly Rate")
                        Spacer()
                        Text(formatCurrency(caregiver.hourlyRate))
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Total Amount")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(formatCurrency(totalAmount))
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                    }
                } header: {
                    Text("Summary")
                }
            }
            .navigationTitle("Generate Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Generate") {
                        generateReceipt()
                    }
                    .fontWeight(.semibold)
                    .disabled(providerName.isEmpty || clientName.isEmpty)
                }
            }
            .sheet(item: $shareItem) { item in
                ShareSheet(items: item.activityItems)
            }
        }
    }
    
    private func generateReceipt() {
        let receiptData = ReceiptData(
            receiptTitle: receiptTitle,
            receiptNumber: receiptNumber,
            startDate: startDate,
            endDate: endDate,
            providerName: providerName,
            providerRole: providerRole,
            serviceProvided: serviceProvided,
            providerPhone: providerPhone,
            providerEmail: includeEmail ? providerEmail : nil,
            providerAddress: includeAddress ? providerAddress : nil,
            providerTaxId: includeTaxId ? providerTaxId : nil,
            clientName: clientName,
            clientPhone: clientPhone.isEmpty ? nil : clientPhone,
            clientEmail: clientEmail.isEmpty ? nil : clientEmail,
            clientAddress: clientAddress.isEmpty ? nil : clientAddress,
            notes: notes.isEmpty ? nil : notes,
            includeSignatureLine: includeSignatureLine,
            includeClientSignature: includeClientSignature,
            includeProviderTaxId: includeTaxId,
            includeProviderEmail: includeEmail,
            includeProviderAddress: includeAddress
        )
        
        if let pdfData = ReceiptGenerator.generateReceiptPDF(
            shifts: shifts,
            caregiver: caregiver,
            receiptData: receiptData
        ) {
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("Childcare_Receipt_\(receiptNumber).pdf")
            
            do {
                try pdfData.write(to: tempURL)
                shareItem = ShareItem(url: tempURL)
            } catch {
                print("Error saving PDF: \(error)")
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

// MARK: - Receipt Data Model

struct ReceiptData {
    let receiptTitle: String
    let receiptNumber: String
    let startDate: Date
    let endDate: Date
    let providerName: String
    let providerRole: String
    let serviceProvided: String
    let providerPhone: String
    let providerEmail: String?
    let providerAddress: String?
    let providerTaxId: String?
    let clientName: String
    let clientPhone: String?
    let clientEmail: String?
    let clientAddress: String?
    let notes: String?
    let includeSignatureLine: Bool
    let includeClientSignature: Bool
    let includeProviderTaxId: Bool
    let includeProviderEmail: Bool
    let includeProviderAddress: Bool
}
