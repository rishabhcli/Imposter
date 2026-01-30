//
//  ImposterUITests.swift
//  ImposterUITests
//
//  UI tests for the Imposter app.
//

import XCTest

final class ImposterUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Home Screen Tests

    @MainActor
    func testLaunchShowsHomeScreen() throws {
        // Verify the home screen title is visible
        XCTAssertTrue(app.staticTexts["Imposter"].exists)
    }

    @MainActor
    func testNewGameButtonExists() throws {
        // Look for new game button by accessibility identifier
        let newGameButton = app.buttons["NewGameButton"]
        XCTAssertTrue(newGameButton.waitForExistence(timeout: 2))
    }

    @MainActor
    func testNewGameNavigatesToSetup() throws {
        let newGameButton = app.buttons["NewGameButton"]
        if newGameButton.waitForExistence(timeout: 2) {
            newGameButton.tap()

            // Verify we navigated to setup screen
            XCTAssertTrue(app.staticTexts["Players"].waitForExistence(timeout: 2) ||
                         app.buttons["AddPlayerButton"].waitForExistence(timeout: 2))
        }
    }

    // MARK: - Player Setup Tests

    @MainActor
    func testAddPlayerButton() throws {
        // Navigate to setup
        let newGameButton = app.buttons["NewGameButton"]
        if newGameButton.waitForExistence(timeout: 2) {
            newGameButton.tap()
        }

        // Find add player button
        let addPlayerButton = app.buttons["AddPlayerButton"]
        XCTAssertTrue(addPlayerButton.waitForExistence(timeout: 2))
    }

    @MainActor
    func testStartGameRequiresThreePlayers() throws {
        // Navigate to setup
        let newGameButton = app.buttons["NewGameButton"]
        if newGameButton.waitForExistence(timeout: 2) {
            newGameButton.tap()
        }

        // Start button should be disabled or show warning with < 3 players
        let startButton = app.buttons["StartGameButton"]
        if startButton.waitForExistence(timeout: 2) {
            // Check if button is disabled
            XCTAssertFalse(startButton.isEnabled)
        }
    }

    // MARK: - Full Game Flow Test

    @MainActor
    func testCompleteGameFlowBasic() throws {
        // Navigate to setup
        let newGameButton = app.buttons["NewGameButton"]
        guard newGameButton.waitForExistence(timeout: 2) else { return }
        newGameButton.tap()

        // Add 3 players (minimum required)
        let addPlayerButton = app.buttons["AddPlayerButton"]
        guard addPlayerButton.waitForExistence(timeout: 2) else { return }

        // We need to add enough players - tap add button twice (app may start with 1 player)
        for _ in 0..<2 {
            if addPlayerButton.exists && addPlayerButton.isEnabled {
                addPlayerButton.tap()
            }
        }

        // Start the game
        let startButton = app.buttons["StartGameButton"]
        if startButton.waitForExistence(timeout: 2) && startButton.isEnabled {
            startButton.tap()

            // Verify we moved to role reveal
            XCTAssertTrue(app.staticTexts["Role Reveal"].waitForExistence(timeout: 2) ||
                         app.buttons["RevealRoleButton"].waitForExistence(timeout: 2))
        }
    }

    // MARK: - Performance Tests

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
