//
//  ContentView.swift
//  Nanny Ledger
//
//  Extracted and improved by assistant
//

import SwiftUI
import UIKit
import SwiftData

struct MainContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor<Shift>(\.date, order: .reverse)]) private var shifts: [Shift]

    @State private var customDate = Date().startOfDayLocal
    @State private var startTime = "22:00"
    @State private var endTime = "08:00"

    // Settings
    @State private var weekStartsOn: Int = 1 // 1=Sun default (US-style)
    @State private var defaults = DefaultHours.standard

    // Output
    @State private var showingShare = false
    @State private var generatedNote = ""

    // Billing
    @State private var rateString: String = "" // dollars per hour
    @State private var appendTotals: Bool = true
    var currentRate: Double { Double(rateString.replacingOccurrences(of: ",", with: ".")) ?? 0 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    quickLogSection
                    customAddSection
                    settingsSection
                    logListSection
                    generateSection
                }
                .padding()
            }
            .navigationTitle("Night Nanny Logger")
            .toolbar { EditButton() }
        }
    }
}

// MARK: - Sections
private extension MainContentView {
    var quickLogSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick log").font(.headline)
            HStack {
                Button {
                    let today = Date().startOfDayLocal
                    let (s, e) = defaults.startEnd(for: today)
                    addShift(date: today, start: s, end: e)
                } label: {
                    Label("Log Tonight", systemImage: "moon.stars.fill")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    let y = Calendar.current.date(byAdding: .day, value: -1, to: Date())!.startOfDayLocal
                    let (s, e) = defaults.startEnd(for: y)
                    addShift(date: y, start: s, end: e)
                } label: {
                    Label("Log Last Night", systemImage: "clock.arrow.circlepath")
                }
                .buttonStyle(.bordered)
            }
        }
    }

    var customAddSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add a specific night").font(.headline)
            DatePicker("Night of", selection: $customDate, displayedComponents: .date)
                .datePickerStyle(.compact)
            HStack {
                TextField("Start (24h) e.g. 22:00", text: $startTime)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numbersAndPunctuation)
                TextField("End e.g. 08:00", text: $endTime)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numbersAndPunctuation)
                Button("Add") { addShift(date: customDate, start: startTime, end: endTime) }
                    .buttonStyle(.bordered)
            }
        }
    }

    var settingsSection: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 8) {
                Picker("Week starts on", selection: $weekStartsOn) {
                    Text("Sun").tag(1); Text("Mon").tag(2); Text("Tue").tag(3)
                    Text("Wed").tag(4); Text("Thu").tag(5); Text("Fri").tag(6); Text("Sat").tag(7)
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Default hours by weekday").font(.subheadline).bold()
                    ForEach(1...7, id: \.self) { wd in
                        HStack {
                            Text(shortName(for: wd)).frame(width: 28, alignment: .leading)
                            TextField("Start", text: Binding(
                                get: { defaults.weekdayStartEnd[wd]?.0 ?? "" },
                                set: { value in
                                    ensureDefaultsKey(wd)
                                    defaults.weekdayStartEnd[wd]?.0 = value
                                })
                            )
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numbersAndPunctuation)
                            Text("–")
                            TextField("End", text: Binding(
                                get: { defaults.weekdayStartEnd[wd]?.1 ?? "" },
                                set: { value in
                                    ensureDefaultsKey(wd)
                                    defaults.weekdayStartEnd[wd]?.1 = value
                                })
                            )
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numbersAndPunctuation)
                        }
                    }
                }
            }
        } label: {
            Label("Settings", systemImage: "gearshape")
        }
    }

    var logListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            List {
                Section("Logged nights") {
                    ForEach(shifts) { shift in
                        VStack(alignment: .leading) {
                            Text(formattedDate(shift.date)).font(.headline)
                            Text("\(shift.startTime)–\(shift.endTime)").foregroundStyle(.secondary)
                        }
                    }
                    .onDelete(perform: deleteShifts)
                }
            }
            .frame(maxHeight: 300)
            .listStyle(.insetGrouped)
        }
    }

    var generateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Quick counters (Week‑to‑Date)
            VStack(alignment: .leading, spacing: 6) {
                let wtdInfo = totalsWTD()
                HStack {
                    Text("This week:").font(.subheadline).bold()
                    Text("\(wtdInfo.count) night\(wtdInfo.count == 1 ? "" : "s") (~\(formatHours(wtdInfo.hours)))")
                        .font(.subheadline)
                }
                HStack {
                    Text("Rate: $")
                    TextField("e.g. 35", text: Binding(get: { rateString }, set: { rateString = $0 }))
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                        .frame(maxWidth: 120)
                    Spacer()
                    Text("Total due: $")
                    Text("\(formatMoney(wtdInfo.totalDue(currentRate)))").bold()
                }
                Toggle("Append totals to note", isOn: $appendTotals).font(.caption)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))

            HStack {
                Button {
                    generatedNote = generateNoteWTD()
                    UIPasteboard.general.string = generatedNote
                } label: { Label("Copy Week‑to‑Date", systemImage: "calendar") }
                .buttonStyle(.borderedProminent)

                Button {
                    generatedNote = generateNoteAll()
                    UIPasteboard.general.string = generatedNote
                } label: { Label("Copy Full Note", systemImage: "doc.on.clipboard") }
                .buttonStyle(.bordered)

                Button {
                    showingShare = true
                } label: { Label("Share…", systemImage: "square.and.arrow.up") }
                .buttonStyle(.bordered)
                .sheet(isPresented: $showingShare) { ActivityShareSheet(items: [generatedNote]) }
            }

            TextEditor(text: $generatedNote)
                .frame(minHeight: 100)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary))
        }
    }
}

// MARK: - Actions & Logic
private extension MainContentView {
    func ensureDefaultsKey(_ wd: Int) {
        if defaults.weekdayStartEnd[wd] == nil {
            defaults.weekdayStartEnd[wd] = (defaultStart(), defaultEnd())
        }
    }

    func addShift(date: Date, start: String, end: String) {
        let day = Calendar.current.startOfDay(for: date)
        // Check duplicate
        let descriptor = FetchDescriptor<Shift>(predicate: #Predicate { $0.date == day })
        if let existing = try? modelContext.fetch(descriptor), !existing.isEmpty { return }
        let shift = Shift(date: day, startTime: start, endTime: end)
        modelContext.insert(shift)
        try? modelContext.save()
    }

    func deleteShifts(at offsets: IndexSet) {
        for index in offsets { modelContext.delete(shifts[index]) }
        try? modelContext.save()
    }

    func generateNote(from shifts: [Shift]) -> String {
        // Use NoteGenerator with current settings
        return NoteGenerator.generateFullNote(shifts: shifts, rate: currentRate)
    }

    func generateNoteWTD() -> String {
        let today = Date()
        let start = startOfWeek(for: today, weekStartsOn: weekStartsOn)
        let end = endOfWeekUpToToday(for: today)
        let filtered = shifts.filter { $0.date >= start && $0.date <= end }
        return NoteGenerator.generateWeekNote(shifts: filtered, rate: currentRate, appendTotals: appendTotals)
    }

    func generateNoteAll() -> String { generateNote(from: shifts) }

    func uniformHours(in shifts: [Shift]) -> String? {
        guard let first = shifts.first else { return nil }
        let pair = (first.startTime, first.endTime)
        for s in shifts { if s.startTime != pair.0 || s.endTime != pair.1 { return nil } }
        return "\(pair.0)–\(pair.1)"
    }

    func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("EEE, MMM d, yyyy")
        return f.string(from: date)
    }

    func shortName(for weekday: Int) -> String {
        let symbols = Calendar.current.shortWeekdaySymbols // Sun..Sat
        return symbols[(weekday - 1 + symbols.count) % symbols.count]
    }

    func parseMinutes(_ hhmm: String) -> Int? {
        let parts = hhmm.split(separator: ":")
        guard parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]), (0..<24).contains(h), (0..<60).contains(m) else { return nil }
        return h * 60 + m
    }

    func durationHours(start: String, end: String) -> Double {
        guard let s = parseMinutes(start), let e = parseMinutes(end) else { return 0 }
        let minutes = e >= s ? (e - s) : (e + 24*60 - s)
        return Double(minutes) / 60.0
    }

    func totalHours(for shifts: [Shift]) -> Double {
        shifts.reduce(0) { $0 + durationHours(start: $1.startTime, end: $1.endTime) }
    }

    func formatHours(_ hours: Double) -> String {
        let quarter = (hours * 4).rounded() / 4
        return String(format: "%.2f", quarter)
    }

    func formatMoney(_ amount: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
    }

    func totalsWTD() -> (count: Int, hours: Double, totalDue: (Double) -> Double) {
        let today = Date()
        let start = startOfWeek(for: today, weekStartsOn: weekStartsOn)
        let end = endOfWeekUpToToday(for: today)
        let filtered = shifts.filter { $0.date >= start && $0.date <= end }
        let count = filtered.count
        let hours = totalHours(for: filtered)
        return (count, hours, { rate in hours * rate })
    }
}

