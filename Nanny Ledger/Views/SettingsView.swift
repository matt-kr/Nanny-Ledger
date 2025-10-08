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
    @State private var shareItems: [Any] = []
    
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
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Share Ledger")
                                    .foregroundColor(.primary)
                                Text("Invite someone to collaborate")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
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
            .sheet(isPresented: $showingShareSheet) {
                if !shareItems.isEmpty {
                    CloudKitShareSheet(items: shareItems)
                }
            }
        }
    }
    
    private func shareData() {
        Task {
            do {
                // Get all shifts to share
                let descriptor = FetchDescriptor<Shift>()
                let shifts = try modelContext.fetch(descriptor)
                
                // For now, we'll create a share sheet with the container
                // In a production app, this would create a proper CKShare
                let container = modelContext.container
                
                // Create share using CloudKit
                let share = try await createCloudKitShare(for: container)
                shareItems = [share]
                showingShareSheet = true
            } catch {
                print("Error sharing: \(error)")
            }
        }
    }
    
    private func createCloudKitShare(for container: ModelContainer) async throws -> CKShare {
        // This creates a CloudKit share for the entire container
        let share = CKShare(rootRecord: CKRecord(recordType: "NannyLedgerData"))
        share[CKShare.SystemFieldKey.title] = "Nanny Ledger" as CKRecordValue
        share.publicPermission = .none
        return share
    }
}

// CloudKit Share Sheet wrapper
struct CloudKitShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UICloudSharingController {
        guard let share = items.first as? CKShare else {
            // Fallback to regular activity controller
            return UICloudSharingController { controller, completion in
                completion(nil, nil)
            }
        }
        
        let controller = UICloudSharingController { controller, preparationHandler in
            // Prepare the share
            preparationHandler(share, CKContainer.default(), nil)
        }
        
        controller.availablePermissions = [.allowReadWrite, .allowPrivate]
        controller.delegate = context.coordinator
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            print("Failed to save share: \(error)")
        }
        
        func itemTitle(for csc: UICloudSharingController) -> String? {
            "Nanny Ledger"
        }
    }
        }
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
