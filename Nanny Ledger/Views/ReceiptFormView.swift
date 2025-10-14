//
//  ReceiptFormView.swift
//  Nanny Ledger
//
//  Created by Matt Krussow on 10/13/25.
//

import SwiftUI
import SwiftData

struct ReceiptFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let shifts: [Shift]
    let caregiver: Caregiver
    let settings: AppSettings
    
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
    
    // Client Information (bound to settings for persistence)
    @State private var clientName: String
    @State private var clientAddress: String
    @State private var clientPhone: String
    @State private var clientEmail: String
    
    // Toggles
    @State private var includeSignatureLine: Bool = true
    @State private var includeClientSignature: Bool = true
    @State private var includeAddress: Bool = true
    @State private var includeTaxId: Bool = true
    @State private var includeEmail: Bool = true
    
    // Payment Information
    @State private var markAsPaid: Bool
    @State private var paymentDate: Date = Date()
    @State private var paymentMethod: String
    
    @State private var shareItem: ShareItem?
    @State private var isGeneratingPDF: Bool = false
    
    init(shifts: [Shift], caregiver: Caregiver, settings: AppSettings) {
        self.shifts = shifts
        self.caregiver = caregiver
        self.settings = settings
        
        // Initialize with caregiver defaults
        _providerName = State(initialValue: caregiver.name)
        _providerRole = State(initialValue: caregiver.role)
        _providerPhone = State(initialValue: caregiver.zelleInfo)
        _receiptNumber = State(initialValue: "NL-\(Int(Date().timeIntervalSince1970))")
        
        // Initialize provider info from settings (persistent)
        _providerEmail = State(initialValue: settings.receiptProviderEmail)
        _providerAddress = State(initialValue: settings.receiptProviderAddress)
        _providerTaxId = State(initialValue: settings.receiptProviderTaxId)
        _serviceProvided = State(initialValue: settings.receiptServiceProvided)
        
        // Initialize date range to current week (using settings week start day)
        let weekStart = Date().startOfWeek(weekStartDay: settings.weekStartDay)
        _startDate = State(initialValue: weekStart)
        _endDate = State(initialValue: Date())
        
        // Initialize client info from settings (persistent)
        _clientName = State(initialValue: settings.receiptClientName)
        _clientPhone = State(initialValue: settings.receiptClientPhone)
        _clientEmail = State(initialValue: settings.receiptClientEmail)
        _clientAddress = State(initialValue: settings.receiptClientAddress)
        
        // Initialize payment options from settings (persistent)
        _markAsPaid = State(initialValue: settings.receiptMarkAsPaid)
        _paymentMethod = State(initialValue: settings.receiptPaymentMethod)
    }
    
    // Computed property for filtered shifts based on date range
    private var filteredShifts: [Shift] {
        shifts.filter { shift in
            let shiftDate = Calendar.current.startOfDay(for: shift.date)
            let start = Calendar.current.startOfDay(for: startDate)
            let end = Calendar.current.startOfDay(for: endDate)
            return shiftDate >= start && shiftDate <= end
        }
    }
    
    private var totalHours: Double {
        filteredShifts.reduce(0.0) { $0 + $1.roundedHours }
    }
    
    private var totalAmount: Double {
        totalHours * caregiver.hourlyRate
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
                        .tint(.purple)
                    Toggle("Include Client Signature Line", isOn: $includeClientSignature)
                        .tint(.purple)
                    
                    Toggle("Payment Options", isOn: $markAsPaid)
                        .tint(.purple)
                    
                    if markAsPaid {
                        DatePicker("Payment Date", selection: $paymentDate, displayedComponents: .date)
                        
                        Picker("Payment Method", selection: $paymentMethod) {
                            Text("Cash").tag("Cash")
                            Text("Check").tag("Check")
                            Text("Zelle").tag("Zelle")
                            Text("Venmo").tag("Venmo")
                            Text("CashApp").tag("CashApp")
                            Text("PayPal").tag("PayPal")
                            Text("Bank Transfer").tag("Bank Transfer")
                            Text("Mark Manually (checkbox)").tag("Manual")
                            Text("Other").tag("Other")
                        }
                    }
                    
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
                    TextField("Service Provided", text: $serviceProvided)
                    TextField("Phone", text: $providerPhone)
                        .keyboardType(.phonePad)
                    
                    Toggle("Include Email", isOn: $includeEmail)
                        .tint(.purple)
                    if includeEmail {
                        TextField("Email", text: $providerEmail)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                    }
                    
                    Toggle("Include Address", isOn: $includeAddress)
                        .tint(.purple)
                    if includeAddress {
                        TextField("Address", text: $providerAddress, axis: .vertical)
                            .lineLimit(2...4)
                    }
                    
                    Toggle("Include SSN / EIN", isOn: $includeTaxId)
                        .tint(.purple)
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
                    HStack {
                        Text("Shifts (in date range)")
                        Spacer()
                        Text("\(filteredShifts.count)")
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
            .navigationTitle("Receipt Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isGeneratingPDF)
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Generate") {
                        generateReceipt()
                    }
                    .disabled(providerName.isEmpty || clientName.isEmpty || isGeneratingPDF)
                }
            }
            .sheet(item: $shareItem) { item in
                ShareSheet(items: item.activityItems)
            }
            .overlay {
                if isGeneratingPDF {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            Text("Generating Receipt...")
                                .foregroundStyle(.white)
                                .font(.headline)
                        }
                        .padding(30)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .shadow(radius: 10)
                    }
                }
            }
        }
    }
    
    private func generateReceipt() {
        isGeneratingPDF = true
        
        // Save client info to settings for persistence
        settings.receiptClientName = clientName
        settings.receiptClientPhone = clientPhone
        settings.receiptClientEmail = clientEmail
        settings.receiptClientAddress = clientAddress
        
        // Save provider info to settings for persistence
        settings.receiptProviderEmail = providerEmail
        settings.receiptProviderAddress = providerAddress
        settings.receiptProviderTaxId = providerTaxId
        settings.receiptServiceProvided = serviceProvided
        
        // Save payment options to settings for persistence
        settings.receiptMarkAsPaid = markAsPaid
        settings.receiptPaymentMethod = paymentMethod
        
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
            includeProviderAddress: includeAddress,
            markAsPaid: markAsPaid,
            paymentDate: markAsPaid ? paymentDate : nil,
            paymentMethod: markAsPaid ? paymentMethod : nil
        )
        
        // Small delay to allow loading indicator to appear, then generate PDF on main thread
        // (WebKit requires main thread for HTML rendering)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let pdfData = ReceiptGenerator.generateReceiptPDF(
                shifts: self.shifts,
                caregiver: self.caregiver,
                receiptData: receiptData
            )
            
            if let pdfData = pdfData {
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("Childcare_Receipt_\(self.receiptNumber).pdf")
                
                do {
                    try pdfData.write(to: tempURL)
                    self.shareItem = ShareItem(url: tempURL)
                } catch {
                    print("Error saving PDF: \(error)")
                }
            }
            
            self.isGeneratingPDF = false
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
    let markAsPaid: Bool
    let paymentDate: Date?
    let paymentMethod: String?
}
