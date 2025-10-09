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
    
    @State private var cloudKitShare: CKShare?
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isCreatingShare = false
    
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
            .onChange(of: cloudKitShare) { oldValue, newValue in
                if let share = newValue {
                    presentCloudKitShareController(share: share)
                }
            }
        }
    }
    
    private func shareData() {
        isCreatingShare = true
        
        Task {
            do {
                // Get the model container
                let container = modelContext.container
                
                // Create share using CloudKit
                let share = try await CloudKitSharingService.createShare(for: container)
                
                // Small delay to ensure share URL is fully available
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                // Present the share sheet
                await MainActor.run {
                    cloudKitShare = share
                    isCreatingShare = false
                }
            } catch {
                await MainActor.run {
                    isCreatingShare = false
                    errorMessage = "Failed to create share: \(error.localizedDescription)"
                    showingError = true
                }
                print("Error sharing: \(error)")
            }
        }
    }
    
    private func presentCloudKitShareController(share: CKShare) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("❌ Could not find root view controller")
            return
        }
        
        let containerIdentifier = "iCloud.com.mattkrussow.Nanny-Ledger"
        let container = CKContainer(identifier: containerIdentifier)
        
        let shareController = UICloudSharingController(share: share, container: container)
        shareController.availablePermissions = [.allowReadWrite, .allowPrivate]
        shareController.delegate = ShareDelegate.shared
        
        // Find the topmost presented view controller
        var topController = rootViewController
        while let presented = topController.presentedViewController {
            topController = presented
        }
        
        topController.present(shareController, animated: true) {
            // Reset the cloudKitShare after presentation
            self.cloudKitShare = nil
        }
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
