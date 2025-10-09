//
//  SettingsView.swift
//  Nanny Ledger
//
//  Created by Matt Krussow on 10/8/25.
//

import SwiftUI
import SwiftData
import CloudKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var settings: AppSettings
    
        @State private var showingShareSheet = false
    @State private var shareController: UICloudSharingController?
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isCreatingShare = false
    @State private var activeShare: CKShare?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Payment Recipient") {
                    TextField("Name", text: $settings.recipientName)
                    TextField("Phone Number", text: $settings.recipientPhone)
                        .keyboardType(.phonePad)
                }
                
                Section("General") {
                    Picker("Week Starts On", selection: $settings.weekStartDay) {
                        Text("Sunday").tag(1)
                        Text("Monday").tag(2)
                    }
                    
                    HStack {
                        Text("Hourly Rate")
                        Spacer()
                        TextField("Rate", value: $settings.hourlyRate, format: .currency(code: "USD"))
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("Appearance") {
                    Picker("Color Scheme", selection: $settings.colorScheme) {
                        Text("System").tag(0)
                        Text("Light").tag(1)
                        Text("Dark").tag(2)
                    }
                }
                
                Section {
                    Button {
                        shareData()
                    } label: {
                        HStack {
                            if isCreatingShare {
                                ProgressView()
                                    .padding(.trailing, 8)
                            } else {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(.blue)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(isCreatingShare ? "Creating Share..." : "Share Ledger")
                                    .foregroundColor(.primary)
                                Text("Invite someone to collaborate")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .disabled(isCreatingShare)
                } header: {
                    Text("Collaboration")
                } footer: {
                    Text("Share this ledger with your spouse or partner. They'll be able to view and edit shifts on their device. Both of you need to be signed into iCloud.")
                }
                
                Section("Note Options") {
                    Toggle("Append Totals to Note", isOn: $settings.appendTotalsToNote)
                }
                
                Section("Default Hours by Weekday") {
                    WeekdayTimeRow(
                        day: "Sunday",
                        startTime: $settings.sundayStart,
                        endTime: $settings.sundayEnd
                    )
                    WeekdayTimeRow(
                        day: "Monday",
                        startTime: $settings.mondayStart,
                        endTime: $settings.mondayEnd
                    )
                    WeekdayTimeRow(
                        day: "Tuesday",
                        startTime: $settings.tuesdayStart,
                        endTime: $settings.tuesdayEnd
                    )
                    WeekdayTimeRow(
                        day: "Wednesday",
                        startTime: $settings.wednesdayStart,
                        endTime: $settings.wednesdayEnd
                    )
                    WeekdayTimeRow(
                        day: "Thursday",
                        startTime: $settings.thursdayStart,
                        endTime: $settings.thursdayEnd
                    )
                    WeekdayTimeRow(
                        day: "Friday",
                        startTime: $settings.fridayStart,
                        endTime: $settings.fridayEnd
                    )
                    WeekdayTimeRow(
                        day: "Saturday",
                        startTime: $settings.saturdayStart,
                        endTime: $settings.saturdayEnd
                    )
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Sharing Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func shareData() {
        isCreatingShare = true
        
        Task {
            do {
                let container = CloudKitSharingService.getContainer()
                let privateDatabase = container.privateCloudDatabase
                
                // Create a custom zone for sharing
                let zoneID = CKRecordZone.ID(zoneName: "NannyLedgerSharedZone", ownerName: CKCurrentUserDefaultName)
                let zone = CKRecordZone(zoneID: zoneID)
                
                do {
                    _ = try await privateDatabase.save(zone)
                    print("✅ Zone created")
                } catch let error as CKError {
                    // Zone might already exist - that's okay
                    print("✅ Zone already exists or error: \(error.code)")
                }
                
                // Create a root record for the share
                let rootRecordID = CKRecord.ID(recordName: "SharedLedgerRoot", zoneID: zoneID)
                let rootRecord = CKRecord(recordType: "NannyLedgerData", recordID: rootRecordID)
                rootRecord["title"] = "Nanny Ledger" as CKRecordValue
                rootRecord["createdAt"] = Date() as CKRecordValue
                
                // Create the share
                let share = CKShare(rootRecord: rootRecord)
                share[CKShare.SystemFieldKey.title] = "Nanny Ledger" as CKRecordValue
                share.publicPermission = .none
                
                // Save both records using the modern API
                print("🔵 Saving root record and share to CloudKit...")
                let (saveResults, _) = try await privateDatabase.modifyRecords(
                    saving: [rootRecord, share],
                    deleting: []
                )
                
                print("🔵 Save operation completed. Checking results...")
                print("🔵 Number of save results: \(saveResults.count)")
                
                // Extract the saved share from the results
                var savedShare: CKShare?
                var saveErrors: [Error] = []
                
                for (recordID, result) in saveResults {
                    print("🔵 Processing result for record: \(recordID.recordName)")
                    switch result {
                    case .success(let record):
                        print("✅ Successfully saved record: \(recordID.recordName), type: \(type(of: record))")
                        if let ckShare = record as? CKShare {
                            print("✅ Found the share!")
                            savedShare = ckShare
                        }
                    case .failure(let error):
                        print("❌ Failed to save record \(recordID): \(error.localizedDescription)")
                        saveErrors.append(error)
                    }
                }
                
                // Check if we had any errors
                if !saveErrors.isEmpty {
                    let errorMsg = saveErrors.map { $0.localizedDescription }.joined(separator: "\n")
                    throw NSError(domain: "SettingsView", code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "Errors saving records:\n\(errorMsg)"])
                }
                
                guard let finalShare = savedShare else {
                    print("❌ Share was not found in save results")
                    print("❌ Total results: \(saveResults.count)")
                    print("❌ Results were: \(saveResults.keys.map { $0.recordName })")
                    throw NSError(domain: "SettingsView", code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "Share not in results. Saved \(saveResults.count) records. Check Xcode console for details."])
                }
                
                print("✅ Share created successfully")
                
                // Present the sharing controller with the existing share
                await MainActor.run {
                    self.activeShare = finalShare
                    self.presentCloudKitShareController(share: finalShare, container: container)
                    self.isCreatingShare = false
                }
                
            } catch {
                await MainActor.run {
                    isCreatingShare = false
                    print("❌❌❌ FULL ERROR: \(error)")
                    print("❌❌❌ ERROR DESCRIPTION: \(error.localizedDescription)")
                    if let ckError = error as? CKError {
                        print("❌❌❌ CK ERROR CODE: \(ckError.code)")
                        print("❌❌❌ CK ERROR: \(ckError)")
                    }
                    errorMessage = "Failed to create share: \(error.localizedDescription)"
                    showingError = true
                }
                print("❌ Error creating share: \(error)")
            }
        }
    }
    
    private func presentCloudKitShareController(share: CKShare, container: CKContainer) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("❌ Could not find root view controller")
            errorMessage = "Could not present sharing interface"
            showingError = true
            return
        }
        
        // Create controller with existing share (not deprecated)
        let shareController = UICloudSharingController(share: share, container: container)
        shareController.availablePermissions = [.allowReadWrite, .allowPrivate]
        shareController.delegate = ShareDelegate.shared
        
        // Find the topmost presented view controller
        var topController = rootViewController
        while let presented = topController.presentedViewController {
            topController = presented
        }
        
        topController.present(shareController, animated: true)
    }
}

// Shared delegate for UICloudSharingController
class ShareDelegate: NSObject, UICloudSharingControllerDelegate {
    static let shared = ShareDelegate()
    
    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
        print("❌ Failed to save share: \(error)")
    }
    
    func itemTitle(for csc: UICloudSharingController) -> String? {
        "Nanny Ledger"
    }
    
    func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
        print("✅ Share saved via controller")
    }
    
    func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
        print("🛑 Stopped sharing")
    }
}

struct WeekdayTimeRow: View {
    let day: String
    @Binding var startTime: String
    @Binding var endTime: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(day)
                .font(.headline)
            
            HStack {
                Text("Start")
                    .foregroundStyle(.secondary)
                Spacer()
                TextField("HH:mm", text: $startTime)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                    .keyboardType(.numbersAndPunctuation)
            }
            
            HStack {
                Text("End")
                    .foregroundStyle(.secondary)
                Spacer()
                TextField("HH:mm", text: $endTime)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                    .keyboardType(.numbersAndPunctuation)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SettingsView(settings: AppSettings())
}
