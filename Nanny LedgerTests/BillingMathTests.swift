//
//  BillingMathTests.swift
//  Nanny LedgerTests
//
//  Tests for the math that determines what gets paid.
//

import Foundation
import Testing
@testable import Nanny_Ledger

// MARK: - Helpers

private func makeDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
    let components = DateComponents(year: year, month: month, day: day)
    return Calendar.current.date(from: components)!
}

// MARK: - Duration

struct TimeUtilTests {

    @Test func overnightShiftDuration() {
        #expect(TimeUtil.durationHours(start: "22:00", end: "08:00") == 10)
        #expect(TimeUtil.durationHours(start: "21:00", end: "07:00") == 10)
    }

    @Test func daytimeShiftDuration() {
        #expect(TimeUtil.durationHours(start: "09:00", end: "17:00") == 8)
        #expect(TimeUtil.durationHours(start: "22:00", end: "22:30") == 0.5)
    }

    @Test func partialHoursDuration() {
        let duration = TimeUtil.durationHours(start: "22:15", end: "08:45")
        #expect(abs(duration - 10.5) < 0.0001)
    }

    @Test func invalidTimesReturnZero() {
        #expect(TimeUtil.durationHours(start: "banana", end: "08:00") == 0)
        #expect(TimeUtil.durationHours(start: "", end: "") == 0)
    }

    @Test func storageFormatRoundTrips() {
        for hhmm in ["00:00", "08:30", "13:05", "22:00", "23:59"] {
            let date = TimeUtil.date(from: hhmm)
            #expect(date != nil)
            #expect(TimeUtil.hhmm(from: date!) == hhmm)
        }
    }
}

// MARK: - Billing rounding

struct ShiftBillingTests {

    @Test func roundsToNearestQuarterHour() {
        // 10h07m rounds down to 10.0, 10h08m rounds up to 10.25
        let justUnder = Shift(date: Date(), startTime: "22:00", endTime: "08:07")
        #expect(justUnder.roundedHours == 10.0)

        let justOver = Shift(date: Date(), startTime: "22:00", endTime: "08:08")
        #expect(justOver.roundedHours == 10.25)
    }

    @Test func earningsUseRoundedHours() {
        let shift = Shift(date: Date(), startTime: "22:00", endTime: "08:00")
        #expect(shift.earnings(at: 35.0) == 350.0)
        #expect(shift.earnings(at: 42.5) == 425.0)
    }

    @Test func shiftDateNormalizedToStartOfDay() {
        let now = Date()
        let shift = Shift(date: now, startTime: "22:00", endTime: "08:00")
        #expect(shift.date == Calendar.current.startOfDay(for: now))
    }
}

// MARK: - Week boundaries

struct WeekBoundaryTests {

    // July 8, 2026 is a Wednesday
    @Test func sundayWeekStart() {
        let wednesday = makeDate(2026, 7, 8)
        let weekStart = wednesday.startOfWeek(weekStartDay: 1)
        #expect(weekStart == makeDate(2026, 7, 5)) // previous Sunday
    }

    @Test func mondayWeekStart() {
        let wednesday = makeDate(2026, 7, 8)
        let weekStart = wednesday.startOfWeek(weekStartDay: 2)
        #expect(weekStart == makeDate(2026, 7, 6)) // previous Monday
    }

    @Test func weekStartOnItsOwnDay() {
        let sunday = makeDate(2026, 7, 5)
        #expect(sunday.startOfWeek(weekStartDay: 1) == sunday)
    }
}

// MARK: - Date compression

struct DateCompressionTests {

    @Test func consecutiveDatesFormOneRun() {
        let dates = [makeDate(2026, 7, 1), makeDate(2026, 7, 2), makeDate(2026, 7, 3)]
        let runs = DateCompression.compressDates(dates)
        #expect(runs.count == 1)
        #expect(runs[0].start == makeDate(2026, 7, 1))
        #expect(runs[0].end == makeDate(2026, 7, 3))
    }

    @Test func gapsSplitRuns() {
        let dates = [makeDate(2026, 7, 1), makeDate(2026, 7, 2), makeDate(2026, 7, 5)]
        let runs = DateCompression.compressDates(dates)
        #expect(runs.count == 2)
        #expect(runs[1].start == makeDate(2026, 7, 5))
        #expect(runs[1].end == makeDate(2026, 7, 5))
    }

    @Test func duplicateDatesAreDeduped() {
        let dates = [makeDate(2026, 7, 1), makeDate(2026, 7, 1), makeDate(2026, 7, 2)]
        let runs = DateCompression.compressDates(dates)
        #expect(runs.count == 1)
    }

    @Test func unsortedInputIsHandled() {
        let dates = [makeDate(2026, 7, 3), makeDate(2026, 7, 1), makeDate(2026, 7, 2)]
        let runs = DateCompression.compressDates(dates)
        #expect(runs.count == 1)
    }

    @Test func emptyInputGivesNoRuns() {
        #expect(DateCompression.compressDates([]).isEmpty)
        #expect(DateCompression.formatRuns([]) == "")
    }
}

// MARK: - Note generation

struct NoteGeneratorTests {

    @Test func weekNoteTotalsMatchRateAndHours() {
        let shifts = [
            Shift(date: makeDate(2026, 7, 5), startTime: "22:00", endTime: "08:00"),
            Shift(date: makeDate(2026, 7, 6), startTime: "22:00", endTime: "08:00"),
        ]
        let note = NoteGenerator.generateWeekNote(shifts: shifts, rate: 35.0, appendTotals: true)
        #expect(note.contains("2 nights"))
        #expect(note.contains("20.00h"))
    }

    @Test func emptyShiftsProduceFallbackNotes() {
        #expect(NoteGenerator.generateZelleNote(shifts: []) == "No shifts this week")
        #expect(NoteGenerator.generateWeekNote(shifts: [], rate: 35, appendTotals: true) == "No shifts logged this week")
    }

    @Test func zelleNoteListsDatesInOrder() {
        let shifts = [
            Shift(date: makeDate(2026, 7, 6), startTime: "22:00", endTime: "08:00"),
            Shift(date: makeDate(2026, 7, 5), startTime: "22:00", endTime: "08:00"),
        ]
        let note = NoteGenerator.generateZelleNote(shifts: shifts)
        // Sorted ascending regardless of input order: "Sun 5 Jul, Mon 6 Jul"
        let sundayIndex = note.range(of: "5")?.lowerBound
        let mondayIndex = note.range(of: "6")?.lowerBound
        #expect(sundayIndex != nil && mondayIndex != nil)
        #expect(sundayIndex! < mondayIndex!)
    }
}
