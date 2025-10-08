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
    
    @State private var showingAddSheet = false
    @State private var showingSettings = false
    @State private var showingShareSheet = false
    @State private var shareText = ""
    
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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Week Summary Header
                    weekSummaryCard
                    
                    // Recipient Info
                    recipientInfoSection
                    
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
            .navigationTitle("Nanny Ledger")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddShiftView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(settings: settings)
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [shareText])
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
            
            Text("Rate: \(formatCurrency(settings.hourlyRate))/hour")
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
            Text("Logged Nights")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if allShifts.isEmpty {
                Text("No shifts logged yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                ForEach(allShifts) { shift in
                    ShiftRowView(shift: shift)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteShift(shift)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
    }
    
    // MARK: - Recipient Info Section
    
    private var recipientInfoSection: some View {
        VStack(spacing: 8) {
            Text("Payment To")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(settings.recipientName.isEmpty ? "Tap to add name" : settings.recipientName)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    if !settings.recipientPhone.isEmpty {
                        Text(settings.recipientPhone)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Computed Properties
    
    private var weekShifts: [Shift] {
        let weekStart = Date().startOfWeek(weekStartDay: settings.weekStartDay)
        return allShifts.filter { $0.date >= weekStart }
    }
    
    private var weekHours: Double {
        weekShifts.reduce(0.0) { $0 + $1.roundedHours }
    }
    
    private var weekTotal: Double {
        weekHours * settings.hourlyRate
    }
    
    private var zelleNote: String {
        NoteGenerator.generateZelleNote(shifts: weekShifts)
    }
    
    // MARK: - Actions
    
    private func logTonight() {
        let today = Date()
        let defaults = settings.defaultTimes(for: today)
        
        let shift = Shift(
            date: today,
            startTime: defaults.start,
            endTime: defaults.end
        )
        
        modelContext.insert(shift)
        try? modelContext.save()
    }
    
    private func logLastNight() {
        let yesterday = Date().addingDays(-1)
        let defaults = settings.defaultTimes(for: yesterday)
        
        let shift = Shift(
            date: yesterday,
            startTime: defaults.start,
            endTime: defaults.end
        )
        
        modelContext.insert(shift)
        try? modelContext.save()
    }
    
    private func deleteShift(_ shift: Shift) {
        modelContext.delete(shift)
        try? modelContext.save()
    }
    
    private func copyWeekNote() {
        let note = NoteGenerator.generateWeekNote(
            shifts: weekShifts,
            rate: settings.hourlyRate,
            appendTotals: settings.appendTotalsToNote
        )
        UIPasteboard.general.string = note
    }
    
    private func shareWeekNote() {
        shareText = NoteGenerator.generateWeekNote(
            shifts: weekShifts,
            rate: settings.hourlyRate,
            appendTotals: settings.appendTotalsToNote
        )
        showingShareSheet = true
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
}

// MARK: - Share Sheet

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
