//
//  ImposterUITests.swift
//  ImposterUITests
//
//  UI tests for the Imposter app.
//

import XCTest

final class ImposterUITests: XCTestCase {

    var app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = XCUIApplication()
    }

    // MARK: - Home Screen Tests

    @MainActor
    func testLaunchShowsHomeScreen() throws {
        XCTAssertTrue(app.staticTexts[UITestAccessibilityIDs.homeTitle].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons[UITestAccessibilityIDs.newGameButton].exists)
    }

    @MainActor
    func testNewGameFlowReachesPlayerSetup() throws {
        goToPlayerSetup()
        XCTAssertTrue(app.buttons[UITestAccessibilityIDs.startGameButton].exists)
    }

    @MainActor
    func testCompleteGameFlowBasic() throws {
        goToPlayerSetup()

        let addPlayerButton = app.buttons[UITestAccessibilityIDs.addPlayerButton]
        let startButton = app.buttons[UITestAccessibilityIDs.startGameButton]

        if !startButton.isEnabled {
            for _ in 0..<3 {
                guard addPlayerButton.exists, addPlayerButton.isEnabled else { break }
                addPlayerButton.tap()
                if startButton.isEnabled { break }
            }
        }

        XCTAssertTrue(startButton.exists)

        if startButton.isEnabled {
            startButton.tap()
            XCTAssertTrue(app.staticTexts["Role Reveal"].waitForExistence(timeout: 3))
            XCTAssertTrue(app.buttons["Hold to Reveal My Role"].waitForExistence(timeout: 3))
        }
    }

    // MARK: - Performance Tests

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    // MARK: - Helpers

    @MainActor
    private func goToPlayerSetup() {
        let newGameButton = app.buttons[UITestAccessibilityIDs.newGameButton]
        XCTAssertTrue(newGameButton.waitForExistence(timeout: 3))
        newGameButton.tap()

        let continueButton = app.buttons[UITestAccessibilityIDs.categoryContinueButton]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 3))
        continueButton.tap()

        XCTAssertTrue(app.buttons[UITestAccessibilityIDs.startGameButton].waitForExistence(timeout: 3))
    }
}

private enum UITestAccessibilityIDs {
    static let homeTitle = "homeTitle"
    static let newGameButton = "newGameButton"
    static let addPlayerButton = "addPlayerButton"
    static let startGameButton = "startGameButton"
    static let categoryContinueButton = "categoryContinueButton"
}
