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
    @Bindable var settings: AppSettings
    
    var body: some View {
        NavigationStack {
            Form {
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
