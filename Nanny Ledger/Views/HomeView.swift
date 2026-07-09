//
//  HomeView.swift
//  Nanny Ledger
//
//  Created by Matt Krussow on 10/8/25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Shift.date, order: .reverse) private var allShifts: [Shift]
    @Query private var settingsQuery: [AppSettings]
    @Query(sort: \Caregiver.createdDate) private var allCaregivers: [Caregiver]

    @State private var showingAddSheet = false
    @State private var showingSettings = false
    @State private var shareItem: ShareItem?
    @State private var showingHistory = false
    @State private var shiftToDelete: Shift?
    @State private var showingDeleteConfirmation = false
    @State private var shiftToEdit: Shift?
    @State private var selectedCaregiver: Caregiver?
    @State private var showingDuplicateAlert = false
    @State private var duplicateAlertMessage = ""
    @State private var showingReceiptForm = false
    @State private var showingYearSummary = false
    @State private var justLogged = false
    @State private var copiedNote = false

    private var settings: AppSettings {
        settingsQuery.first ?? AppSettings()
    }

    private var currentCaregiver: Caregiver? {
        selectedCaregiver
            ?? allCaregivers.first { $0.id == settings.lastSelectedCaregiverId }
            ?? allCaregivers.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let caregiver = currentCaregiver {
                    VStack(spacing: 20) {
                        caregiverPicker(current: caregiver)
                        heroCard(for: caregiver)
                        logTonightButton
                        quickActionsRow
                        if !weekShifts.isEmpty {
                            paymentNoteCard
                        }
                        shiftListSection(for: caregiver)
                        documentationSection
                    }
                    .padding()
                } else {
                    ProgressView()
                        .padding(.top, 100)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "moon.stars.fill")
                            .font(.title3)
                            .foregroundStyle(Theme.gradient)

                        Text("Nanny Ledger")
                            .font(.title2.bold())
                            .foregroundStyle(Theme.gradient)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .preferredColorScheme(colorSchemeForSetting(settings.colorScheme))
            .task { ensureSetup() }
            .sheet(isPresented: $showingAddSheet) {
                if let caregiver = currentCaregiver {
                    AddShiftView(defaultCaregiver: caregiver)
                }
            }
            .sheet(isPresented: $showingSettings) {
                if let settings = settingsQuery.first {
                    SettingsView(settings: settings)
                }
            }
            .sheet(item: $shareItem) { item in
                ShareSheet(items: item.activityItems)
            }
            .sheet(isPresented: $showingHistory) {
                if let caregiver = currentCaregiver {
                    HistoryView(caregiver: caregiver)
                }
            }
            .sheet(isPresented: $showingReceiptForm) {
                if let caregiver = currentCaregiver, let settings = settingsQuery.first {
                    ReceiptFormView(shifts: caregiverShifts, caregiver: caregiver, settings: settings)
                }
            }
            .sheet(item: $shiftToEdit) { shift in
                EditShiftView(shift: shift)
            }
            .sheet(isPresented: $showingYearSummary) {
                if let caregiver = currentCaregiver {
                    YearSummaryView(caregiver: caregiver)
                }
            }
            .alert("Delete Shift?", isPresented: $showingDeleteConfirmation, presenting: shiftToDelete) { shift in
                Button("Cancel", role: .cancel) {
                    shiftToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let shift = shiftToDelete {
                        modelContext.delete(shift)
                        try? modelContext.save()
                    }
                    shiftToDelete = nil
                }
            } message: { shift in
                Text("\(shift.date.formattedWithWeekday())\n\(shift.timeRangeDisplay)")
            }
            .alert("Already Logged", isPresented: $showingDuplicateAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(duplicateAlertMessage)
            }
        }
    }

    // MARK: - Setup

    private func ensureSetup() {
        // Create settings on first launch
        let appSettings: AppSettings
        if let existing = settingsQuery.first {
            appSettings = existing
        } else {
            appSettings = AppSettings()
            modelContext.insert(appSettings)
        }

        // Ensure a default caregiver exists and adopt any orphaned shifts
        let caregiver = CaregiverMigration.ensureDefaultCaregiver(modelContext: modelContext, settings: appSettings)

        if selectedCaregiver == nil {
            selectedCaregiver = allCaregivers.first { $0.id == appSettings.lastSelectedCaregiverId } ?? caregiver
        }

        try? modelContext.save()
    }

    // MARK: - Caregiver Picker

    private func caregiverPicker(current: Caregiver) -> some View {
        Menu {
            ForEach(allCaregivers, id: \.id) { caregiver in
                Button {
                    selectedCaregiver = caregiver
                    settings.lastSelectedCaregiverId = caregiver.id
                    try? modelContext.save()
                } label: {
                    HStack {
                        Text(caregiver.displayName)
                        if caregiver.id == current.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }

            Divider()

            Button {
                showingSettings = true
            } label: {
                Label("Manage Caregivers", systemImage: "person.badge.plus")
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Theme.gradient.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Text(String(current.name.prefix(1)).uppercased())
                        .font(.headline)
                        .foregroundStyle(Theme.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(current.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(subtitle(for: current))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .cardStyle(padding: 12)
        }
        .buttonStyle(.plain)
    }

    private func subtitle(for caregiver: Caregiver) -> String {
        var parts: [String] = []
        if !caregiver.role.isEmpty && caregiver.role != caregiver.name {
            parts.append(caregiver.role)
        }
        parts.append("\(caregiver.hourlyRate.currencyString)/hr")
        if !caregiver.zelleInfo.isEmpty {
            parts.append(caregiver.zelleInfo)
        }
        return parts.joined(separator: " · ")
    }

    // MARK: - Hero Card

    private func heroCard(for caregiver: Caregiver) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("This Week")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(weekRangeLabel)
                    .font(.caption)
                    .opacity(0.85)
            }

            HStack(spacing: 0) {
                heroStat(value: "\(weekShifts.count)", label: weekShifts.count == 1 ? "night" : "nights")
                heroDivider
                heroStat(value: weekHours.hoursString, label: "hours")
                heroDivider
                heroStat(value: weekTotal(for: caregiver).currencyString, label: "total due")
            }

            if earlierUnpaidTotal(for: caregiver) > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                    Text("Earlier weeks unpaid: \(earlierUnpaidTotal(for: caregiver).currencyString)")
                        .font(.caption.weight(.medium))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.white.opacity(0.18))
                .clipShape(Capsule())
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Theme.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .purple.opacity(0.3), radius: 12, y: 6)
    }

    private var heroDivider: some View {
        Rectangle()
            .fill(.white.opacity(0.25))
            .frame(width: 1, height: 36)
    }

    private func heroStat(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(label)
                .font(.caption)
                .opacity(0.85)
        }
        .frame(maxWidth: .infinity)
    }

    private var weekRangeLabel: String {
        let weekStart = Date().startOfWeek(weekStartDay: settings.weekStartDay)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: weekStart)) – \(formatter.string(from: weekStart.addingDays(6)))"
    }

    // MARK: - Log Tonight Button

    private var logTonightButton: some View {
        Button {
            logShift(for: Date(), dayLabel: "today")
        } label: {
            HStack(spacing: 10) {
                Image(systemName: justLogged ? "checkmark.circle.fill" : "moon.stars.fill")
                    .font(.title3)
                Text(justLogged ? "Logged!" : "Log Today")
                    .font(.title3.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(justLogged ? AnyShapeStyle(.green) : AnyShapeStyle(Theme.gradient))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .purple.opacity(0.25), radius: 8, y: 4)
        }
        .disabled(justLogged)
        .animation(.snappy, value: justLogged)
    }

    // MARK: - Quick Actions

    private var quickActionsRow: some View {
        HStack(spacing: 12) {
            Button {
                logShift(for: Date().addingDays(-1), dayLabel: "yesterday")
            } label: {
                Label("Log Yesterday", systemImage: "moon.fill")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .foregroundColor(.primary)

            Button {
                showingAddSheet = true
            } label: {
                Label("Pick a Date", systemImage: "calendar.badge.plus")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .foregroundColor(.primary)
        }
    }

    // MARK: - Payment Note

    private var paymentNoteCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Payment Note", systemImage: "text.quote")
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }

            Text(zelleNote)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                Button {
                    UIPasteboard.general.string = zelleNote
                    Haptics.tap()
                    withAnimation { copiedNote = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { copiedNote = false }
                    }
                } label: {
                    Label(copiedNote ? "Copied!" : "Copy", systemImage: copiedNote ? "checkmark" : "doc.on.doc")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(copiedNote ? Color.green.opacity(0.15) : Theme.accent.opacity(0.12))
                        .foregroundStyle(copiedNote ? Color.green : Theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                Button {
                    shareWeekNote()
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Theme.accent.opacity(0.12))
                        .foregroundStyle(Theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Shift List

    private func shiftListSection(for caregiver: Caregiver) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("This Week's Care")
                    .font(.headline)

                Spacer()

                if weekShifts.contains(where: { !$0.isPaid }) && !weekShifts.isEmpty {
                    Button {
                        markWeekPaid()
                    } label: {
                        Label("Mark Paid", systemImage: "checkmark.seal")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.accent)
                    }
                }

                if hasHistoricalShifts {
                    Button {
                        showingHistory = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("History")
                            Image(systemName: "clock.arrow.circlepath")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                    }
                }
            }

            if weekShifts.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "moon.zzz")
                        .font(.title)
                        .foregroundStyle(.tertiary)
                    Text("No shifts logged this week")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 36)
            } else {
                VStack(spacing: 8) {
                    ForEach(weekShifts) { shift in
                        ShiftRowView(
                            shift: shift,
                            rate: caregiver.hourlyRate,
                            onDelete: {
                                shiftToDelete = shift
                                showingDeleteConfirmation = true
                            },
                            onTap: {
                                shiftToEdit = shift
                            },
                            onTogglePaid: {
                                shift.isPaid.toggle()
                                try? modelContext.save()
                                Haptics.tap()
                            }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Documentation

    private var documentationSection: some View {
        VStack(spacing: 12) {
            Text("Documentation")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                Button {
                    shareWeekNote()
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                        Text("Share Week")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .foregroundColor(.primary)
                .disabled(weekShifts.isEmpty)

                Button {
                    showingReceiptForm = true
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "doc.plaintext")
                            .font(.title3)
                        Text("Receipt")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .foregroundColor(.primary)
                .disabled(caregiverShifts.isEmpty)

                Button {
                    showingYearSummary = true
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "chart.pie")
                            .font(.title3)
                        Text("Year & Taxes")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .foregroundColor(.primary)
                .disabled(caregiverShifts.isEmpty)
            }
        }
    }

    // MARK: - Computed Properties

    private var caregiverShifts: [Shift] {
        guard let caregiver = currentCaregiver else { return [] }
        return allShifts.filter { $0.caregiver?.id == caregiver.id }
    }

    private var weekShifts: [Shift] {
        let weekStart = Date().startOfWeek(weekStartDay: settings.weekStartDay)
        return caregiverShifts.filter { $0.date >= weekStart }
    }

    private var hasHistoricalShifts: Bool {
        let weekStart = Date().startOfWeek(weekStartDay: settings.weekStartDay)
        return caregiverShifts.contains { $0.date < weekStart }
    }

    private var weekHours: Double {
        weekShifts.reduce(0.0) { $0 + $1.roundedHours }
    }

    private func weekTotal(for caregiver: Caregiver) -> Double {
        weekHours * caregiver.hourlyRate
    }

    private func earlierUnpaidTotal(for caregiver: Caregiver) -> Double {
        let weekStart = Date().startOfWeek(weekStartDay: settings.weekStartDay)
        return caregiverShifts
            .filter { $0.date < weekStart && !$0.isPaid }
            .reduce(0.0) { $0 + $1.earnings(at: caregiver.hourlyRate) }
    }

    private var zelleNote: String {
        NoteGenerator.generateZelleNote(shifts: weekShifts)
    }

    // MARK: - Actions

    private func logShift(for date: Date, dayLabel: String) {
        guard let caregiver = currentCaregiver else { return }

        let dayStart = Calendar.current.startOfDay(for: date)
        let defaults = caregiver.defaultStartTime.isEmpty ?
            settings.defaultTimes(for: date) :
            (start: caregiver.defaultStartTime, end: caregiver.defaultEndTime)

        let duplicateExists = allShifts.contains { shift in
            Calendar.current.startOfDay(for: shift.date) == dayStart &&
            shift.caregiver?.id == caregiver.id
        }

        if duplicateExists {
            duplicateAlertMessage = "You already logged a shift for \(caregiver.name) \(dayLabel). Tap the shift to edit it."
            showingDuplicateAlert = true
            Haptics.warning()
            return
        }

        let shift = Shift(
            date: date,
            startTime: defaults.start,
            endTime: defaults.end,
            caregiver: caregiver
        )

        modelContext.insert(shift)
        try? modelContext.save()
        Haptics.success()

        if Calendar.current.isDateInToday(date) {
            justLogged = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                justLogged = false
            }
        }
    }

    private func markWeekPaid() {
        for shift in weekShifts where !shift.isPaid {
            shift.isPaid = true
        }
        try? modelContext.save()
        Haptics.success()
    }

    private func shareWeekNote() {
        guard let caregiver = currentCaregiver else { return }
        let note = NoteGenerator.generateWeekNote(
            shifts: weekShifts,
            rate: caregiver.hourlyRate,
            appendTotals: settings.appendTotalsToNote
        )
        shareItem = ShareItem(text: note)
    }

    private func colorSchemeForSetting(_ setting: Int) -> ColorScheme? {
        switch setting {
        case 1: return .light
        case 2: return .dark
        default: return nil // System default
        }
    }
}

// MARK: - Share Sheet

struct ShareItem: Identifiable {
    let id = UUID()
    let text: String?
    let url: URL?

    init(text: String) {
        self.text = text
        self.url = nil
    }

    init(url: URL) {
        self.text = nil
        self.url = url
    }

    var activityItems: [Any] {
        if let text = text {
            return [text]
        } else if let url = url {
            return [url]
        }
        return []
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    HomeView()
        .modelContainer(for: [Shift.self, AppSettings.self, Caregiver.self])
}
