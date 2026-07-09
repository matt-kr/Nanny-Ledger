//
//  SettingsView.swift
//  Nanny Ledger
//
//  Created by Matt Krussow on 10/8/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var settings: AppSettings
    @Query(sort: \Caregiver.createdDate) private var caregivers: [Caregiver]

    @State private var showingCaregiversManagement = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Caregivers") {
                    ForEach(caregivers) { caregiver in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(caregiver.name)
                                    .font(.body)
                                if !caregiver.role.isEmpty && caregiver.role != caregiver.name {
                                    Text(caregiver.role)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text("\(caregiver.hourlyRate.currencyString)/hr")
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showingCaregiversManagement = true
                        }
                    }

                    Button {
                        showingCaregiversManagement = true
                    } label: {
                        Label("Manage Caregivers", systemImage: "person.badge.plus")
                    }
                }

                Section("General") {
                    Picker("Week Starts On", selection: $settings.weekStartDay) {
                        Text("Sunday").tag(1)
                        Text("Monday").tag(2)
                    }
                }

                Section {
                    Toggle("Nightly Reminder", isOn: $settings.reminderEnabled)
                        .tint(.purple)

                    if settings.reminderEnabled {
                        TimeField(label: "Remind At", time: $settings.reminderTime)
                    }
                } header: {
                    Text("Reminder")
                } footer: {
                    Text("A daily nudge to log tonight's shift so nothing slips through.")
                }
                .onChange(of: settings.reminderEnabled) { _, _ in
                    syncReminder()
                }
                .onChange(of: settings.reminderTime) { _, _ in
                    syncReminder()
                }

                Section("Appearance") {
                    Picker("Color Scheme", selection: $settings.colorScheme) {
                        Text("System").tag(0)
                        Text("Light").tag(1)
                        Text("Dark").tag(2)
                    }
                }

                Section {
                    HStack {
                        Image(systemName: "icloud.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("iCloud Sync")
                            Text("On automatically")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Sync")
                } footer: {
                    Text("Your ledger syncs automatically between devices signed into the same iCloud account. Sharing with a different iCloud account (like a spouse's) isn't supported yet — it's on the roadmap.")
                }

                Section("Note Options") {
                    Toggle("Append Totals to Note", isOn: $settings.appendTotalsToNote)
                        .tint(.purple)
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
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCaregiversManagement) {
                CaregiversManagementView()
            }
        }
    }

    private func syncReminder() {
        ReminderService.update(enabled: settings.reminderEnabled, time: settings.reminderTime)
    }
}

struct WeekdayTimeRow: View {
    let day: String
    @Binding var startTime: String
    @Binding var endTime: String

    var body: some View {
        DisclosureGroup {
            TimeField(label: "Start", time: $startTime)
            TimeField(label: "End", time: $endTime)
        } label: {
            HStack {
                Text(day)
                Spacer()
                Text("\(TimeUtil.display(startTime)) – \(TimeUtil.display(endTime))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    SettingsView(settings: AppSettings())
}
