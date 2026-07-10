//
//  LogShiftUITests.swift
//  Nanny LedgerUITests
//
//  Smoke test for the core logging flow.
//

import XCTest

final class LogShiftUITests: XCTestCase {

    @MainActor
    func testLogTodayCreatesShift() throws {
        let app = XCUIApplication()
        app.launch()

        // Fresh install: complete onboarding first
        let getStarted = app.buttons["Get Started"]
        if getStarted.waitForExistence(timeout: 10) {
            let nameField = app.textFields["Name"]
            XCTAssertTrue(nameField.waitForExistence(timeout: 3), "Onboarding name field should exist")
            nameField.tap()
            nameField.typeText("Maria")

            // Dismiss the keyboard so it doesn't cover the Get Started button
            let returnKey = app.keyboards.buttons["Return"]
            if returnKey.waitForExistence(timeout: 2) {
                returnKey.tap()
            }

            getStarted.tap()
        }

        let logButton = app.buttons["Log Today"]
        XCTAssertTrue(logButton.waitForExistence(timeout: 10), "Log Today button should exist")
        logButton.tap()

        // If a shift was already logged today (persisted data), dismiss the alert
        let alert = app.alerts["Already Logged"]
        if alert.waitForExistence(timeout: 2) {
            alert.buttons["OK"].tap()
        }

        // The payment note card and week actions should now be visible
        XCTAssertTrue(app.staticTexts["Payment Note"].waitForExistence(timeout: 5), "Payment note card should appear after logging")
        XCTAssertTrue(app.buttons["Mark Paid"].waitForExistence(timeout: 3), "Mark Paid button should appear for unpaid week")

        // Mark the week paid and confirm the button disappears
        app.buttons["Mark Paid"].tap()
        XCTAssertFalse(app.buttons["Mark Paid"].waitForExistence(timeout: 2), "Mark Paid should disappear once the week is paid")
    }
}
