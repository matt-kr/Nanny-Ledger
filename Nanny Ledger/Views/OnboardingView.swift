//
//  OnboardingView.swift
//  Nanny Ledger
//
//  First-run setup: create the first caregiver instead of
//  silently defaulting one into existence.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let settings: AppSettings

    @State private var name = ""
    @State private var role = "Night Nanny"
    @State private var hourlyRate = 35.0
    @State private var startTime = "22:00"
    @State private var endTime = "08:00"

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(Theme.gradient)

                        Text("Welcome to Nanny Ledger")
                            .font(.title2.bold())

                        Text("Track shifts, totals, and payments for your caregiver. Start by telling us who's coming over.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)
                }

                Section("Caregiver") {
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
                }

                Section {
                    TimeField(label: "Usual Start", time: $startTime)
                    TimeField(label: "Usual End", time: $endTime)
                } header: {
                    Text("Typical Hours")
                } footer: {
                    Text("Used for one-tap logging. You can fine-tune per-weekday defaults in Settings later.")
                }

                Section {
                    Button {
                        createCaregiver()
                    } label: {
                        Text("Get Started")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .disabled(name.isEmpty)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled()
    }

    private func createCaregiver() {
        let caregiver = Caregiver(
            name: name,
            role: role,
            hourlyRate: hourlyRate,
            defaultStartTime: startTime,
            defaultEndTime: endTime
        )

        modelContext.insert(caregiver)
        settings.lastSelectedCaregiverId = caregiver.id
        try? modelContext.save()
        Haptics.success()
        dismiss()
    }
}

#Preview {
    OnboardingView(settings: AppSettings())
        .modelContainer(for: [Caregiver.self, AppSettings.self])
}
