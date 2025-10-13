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
    
    private var settings: AppSettings {
        if let existing = settingsQuery.first {
            return existing
        } else {
            let newSettings = AppSettings()
            modelContext.insert(newSettings)
            try? modelContext.save()
            return newSettings
        }
    }
    
    private var currentCaregiver: Caregiver {
        // Ensure default caregiver exists and get it
        let caregiver = CaregiverMigration.ensureDefaultCaregiver(modelContext: modelContext, settings: settings)
        
        // Use selected caregiver if set, otherwise use last selected or default
        if let selected = selectedCaregiver {
            return selected
        }
        
        // Try to restore last selected caregiver
        if let lastId = settings.lastSelectedCaregiverId,
           let lastCaregiver = allCaregivers.first(where: { $0.id == lastId }) {
            DispatchQueue.main.async {
                selectedCaregiver = lastCaregiver
            }
            return lastCaregiver
        }
        
        // Default to first caregiver
        DispatchQueue.main.async {
            selectedCaregiver = caregiver
        }
        return caregiver
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Week Summary Header
                    weekSummaryCard
                    
                    // Caregiver Info/Picker
                    caregiverInfoSection
                    
                    // PROMINENT Log Tonight Button
                    logTonightButton
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Week-to-Date Actions
                    weekActionsSection
                    
                    // Shift List
                    shiftListSection
                }
                .padding()
            }
            .id(currentCaregiver.id) // Force refresh when caregiver changes
            .navigationTitle("Nanny Ledger")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .preferredColorScheme(colorSchemeForSetting(settings.colorScheme))
            .sheet(isPresented: $showingAddSheet) {
                AddShiftView(defaultCaregiver: currentCaregiver)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(settings: settings)
            }
            .sheet(item: $shareItem) { item in
                ShareSheet(items: [item.text])
            }
            .sheet(isPresented: $showingHistory) {
                HistoryView(caregiver: currentCaregiver)
            }
            .sheet(item: $shiftToEdit) { shift in
                EditShiftView(shift: shift)
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
                Text("\(shift.date.formattedWithWeekday())\n\(shift.startTime) – \(shift.endTime)")
            }
        }
    }
    
    // MARK: - Caregiver Info Section
    
    private var caregiverInfoSection: some View {
        VStack(spacing: 0) {
            // Caregiver Picker Menu
            Menu {
                ForEach(allCaregivers, id: \.id) { caregiver in
                    Button {
                        selectedCaregiver = caregiver
                        settings.lastSelectedCaregiverId = caregiver.id
                        try? modelContext.save()
                    } label: {
                        HStack {
                            Text(caregiver.displayName)
                            if caregiver.id == currentCaregiver.id {
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
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentCaregiver.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        if !currentCaregiver.zelleInfo.isEmpty {
                            Text(currentCaregiver.zelleInfo)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .foregroundColor(.primary)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // MARK: - Week Summary Card
    
    private var weekSummaryCard: some View {
        VStack(spacing: 8) {
            Text("This Week")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 20) {
                VStack {
                    Text("\(weekShifts.count)")
                        .font(.system(size: 36, weight: .bold))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    Text(weekShifts.count == 1 ? "night" : "nights")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                VStack {
                    Text(String(format: "%.2f", weekHours))
                        .font(.system(size: 36, weight: .bold))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    Text("hours")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                VStack {
                    Text(formatCurrency(weekTotal))
                        .font(.system(size: 36, weight: .bold))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    Text("total due")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Text("Rate: \(formatCurrency(currentCaregiver.hourlyRate))/hour")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Zelle Payment Note
            if !weekShifts.isEmpty {
                Divider()
                    .padding(.vertical, 4)
                
                VStack(spacing: 4) {
                    Text("Zelle Payment Note")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Button {
                        UIPasteboard.general.string = zelleNote
                    } label: {
                        Text(zelleNote)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.5)
                            .lineLimit(3)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
    
    // MARK: - Log Tonight Button (PROMINENT)
    
    private var logTonightButton: some View {
        Button {
            logTonight()
        } label: {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .font(.title2)
                Text("Log Tonight")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.blue.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
        }
    }
    
    // MARK: - Quick Actions
    
    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            Button {
                logLastNight()
            } label: {
                HStack {
                    Image(systemName: "moon.fill")
                    Text("Log Last Night")
                        .fontWeight(.medium)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .foregroundColor(.primary)
            
            Button {
                showingAddSheet = true
            } label: {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                    Text("Add Specific Night")
                        .fontWeight(.medium)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .foregroundColor(.primary)
        }
    }
    
    // MARK: - Week Actions
    
    private var weekActionsSection: some View {
        VStack(spacing: 12) {
            Text("Week-to-Date Actions")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                Button {
                    copyWeekNote()
                } label: {
                    VStack {
                        Image(systemName: "doc.on.doc")
                        Text("Copy Week")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .foregroundColor(.primary)
                
                Button {
                    shareWeekNote()
                } label: {
                    VStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Week")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .foregroundColor(.primary)
                
                Button {
                    copyFullNote()
                } label: {
                    VStack {
                        Image(systemName: "doc.text")
                        Text("Copy All")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .foregroundColor(.primary)
            }
        }
    }
    
    // MARK: - Shift List
    
    private var shiftListSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("This Week's Nights")
                    .font(.headline)
                
                Spacer()
                
                if hasHistoricalShifts {
                    Button {
                        showingHistory = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("View History")
                                .font(.subheadline)
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.subheadline)
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            
            if weekShifts.isEmpty {
                Text("No shifts logged this week")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                VStack(spacing: 8) {
                    ForEach(weekShifts) { shift in
                        ShiftRowView(
                            shift: shift,
                            onDelete: {
                                shiftToDelete = shift
                                showingDeleteConfirmation = true
                            },
                            onTap: {
                                shiftToEdit = shift
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Recipient Info Section
    
    
    // MARK: - Computed Properties
    
    private var weekShifts: [Shift] {
        let weekStart = Date().startOfWeek(weekStartDay: settings.weekStartDay)
        return allShifts.filter { 
            $0.date >= weekStart && $0.caregiver?.id == currentCaregiver.id
        }
    }
    
    private var hasHistoricalShifts: Bool {
        let weekStart = Date().startOfWeek(weekStartDay: settings.weekStartDay)
        return allShifts.contains { 
            $0.date < weekStart && $0.caregiver?.id == currentCaregiver.id
        }
    }
    
    private var weekHours: Double {
        weekShifts.reduce(0.0) { $0 + $1.roundedHours }
    }
    
    private var weekTotal: Double {
        weekHours * currentCaregiver.hourlyRate
    }
    
    private var zelleNote: String {
        NoteGenerator.generateZelleNote(shifts: weekShifts)
    }
    
    // MARK: - Actions
    
    private func logTonight() {
        let today = Date()
        let defaults = currentCaregiver.defaultStartTime.isEmpty ? 
            settings.defaultTimes(for: today) : 
            (start: currentCaregiver.defaultStartTime, end: currentCaregiver.defaultEndTime)
        
        print("🔵 Logging shift with times: \(defaults.start) - \(defaults.end)")
        print("🔵 Caregiver: \(currentCaregiver.name), Rate: \(currentCaregiver.hourlyRate)")
        
        let shift = Shift(
            date: today,
            startTime: defaults.start,
            endTime: defaults.end,
            caregiver: currentCaregiver
        )
        
        print("🔵 Created shift - Start: \(shift.startTime), End: \(shift.endTime)")
        print("🔵 Shift duration: \(shift.durationHours)h, rounded: \(shift.roundedHours)h")
        
        modelContext.insert(shift)
        try? modelContext.save()
        
        print("✅ Shift saved!")
    }
    
    private func logLastNight() {
        let yesterday = Date().addingDays(-1)
        let defaults = currentCaregiver.defaultStartTime.isEmpty ? 
            settings.defaultTimes(for: yesterday) : 
            (start: currentCaregiver.defaultStartTime, end: currentCaregiver.defaultEndTime)
        
        let shift = Shift(
            date: yesterday,
            startTime: defaults.start,
            endTime: defaults.end,
            caregiver: currentCaregiver
        )
        
        modelContext.insert(shift)
        try? modelContext.save()
    }
    
    private func copyWeekNote() {
        let note = NoteGenerator.generateWeekNote(
            shifts: weekShifts,
            rate: currentCaregiver.hourlyRate,
            appendTotals: settings.appendTotalsToNote
        )
        UIPasteboard.general.string = note
    }
    
    private func shareWeekNote() {
        let note = NoteGenerator.generateWeekNote(
            shifts: weekShifts,
            rate: currentCaregiver.hourlyRate,
            appendTotals: settings.appendTotalsToNote
        )
        shareItem = ShareItem(text: note)
    }
    
    private func copyFullNote() {
        let note = NoteGenerator.generateFullNote(
            shifts: allShifts,
            rate: settings.hourlyRate
        )
        UIPasteboard.general.string = note
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = .current
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
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
    let text: String
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
        .modelContainer(for: [Shift.self, AppSettings.self])
}
