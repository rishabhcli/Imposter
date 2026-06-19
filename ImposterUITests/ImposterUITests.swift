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

        guard shouldLaunchAppInSetUp else { return }

        launchApp()
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
    func testSpanishLocalizedSetupPathUsesCriticalNavigationStrings() throws {
        relaunch(arguments: ["-ui-testing", "-AppleLanguages", "(es)", "-AppleLocale", "es_ES"])

        let newGameButton = app.buttons[UITestAccessibilityIDs.newGameButton]
        XCTAssertTrue(newGameButton.waitForExistence(timeout: 3))
        XCTAssertEqual(newGameButton.label, "Nuevo Juego")

        newGameButton.tap()

        XCTAssertTrue(app.staticTexts["Elegir fuente de palabras"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Elegir categorías"].exists)

        let continueButton = app.buttons[UITestAccessibilityIDs.categoryContinueButton]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 3))
        XCTAssertEqual(continueButton.label, "Continuar")
        continueButton.tap()

        XCTAssertTrue(app.staticTexts["Ajustes del juego"].exists)
        XCTAssertTrue(app.staticTexts["0 jugadores"].exists)
        XCTAssertTrue(app.staticTexts["Añade al menos 3 jugadores"].exists)
        XCTAssertEqual(app.buttons[UITestAccessibilityIDs.startGameButton].label, "Iniciar Juego")
    }

    @MainActor
    func testCompleteGameFlowBasic() throws {
        goToPlayerSetup()

        addMinimumPlayersIfNeeded()

        let startButton = app.buttons[UITestAccessibilityIDs.startGameButton]
        XCTAssertTrue(startButton.exists)

        if startButton.isEnabled {
            startButton.tap()
            waitForElement(identifier: UITestAccessibilityIDs.roleRevealScreen, timeout: 3)
            XCTAssertTrue(app.descendants(matching: .any)[UITestAccessibilityIDs.revealRoleButton].waitForExistence(timeout: 3))
        }
    }

    @MainActor
    func testHostedGameFlowReachesSummaryAndStartsSecondRound() throws {
        goToPlayerSetup()
        addMinimumPlayersIfNeeded()

        app.buttons[UITestAccessibilityIDs.startGameButton].tap()
        waitForElement(identifier: UITestAccessibilityIDs.roleRevealScreen, timeout: 5)

        playCurrentRoundToSummary(playerCount: 3)
        tapButtonWithScrolling(identifier: UITestAccessibilityIDs.playAgainButton, timeout: 5)

        waitForElement(identifier: UITestAccessibilityIDs.roleRevealScreen, timeout: 5)
    }

    @MainActor
    func testRenderedHostedFlowRecordsRuntimeAcrossRepeatedRounds() throws {
        goToPlayerSetup()
        addMinimumPlayersIfNeeded()

        app.buttons[UITestAccessibilityIDs.startGameButton].tap()

        var roundDurations: [TimeInterval] = []
        let totalStart = Date()

        for round in 1...2 {
            waitForElement(identifier: UITestAccessibilityIDs.roleRevealScreen, timeout: 5)

            let roundStart = Date()
            playCurrentRoundToSummary(playerCount: 3)
            let roundDuration = Date().timeIntervalSince(roundStart)
            roundDurations.append(roundDuration)

            XCTAssertLessThan(
                roundDuration,
                90,
                "Rendered round \(round) should stay responsive on the simulator"
            )

            if round < 2 {
                tapButtonWithScrolling(identifier: UITestAccessibilityIDs.playAgainButton, timeout: 5)
            }
        }

        let totalDuration = Date().timeIntervalSince(totalStart)
        let summary = """
        Rendered hosted runtime lab
        Rounds: \(roundDurations.count)
        Round durations: \(roundDurations.map { String(format: "%.3f", $0) }.joined(separator: ", ")) seconds
        Total duration: \(String(format: "%.3f", totalDuration)) seconds
        Device: \(UIDevice.current.name)
        """
        let attachment = XCTAttachment(string: summary)
        attachment.name = "Rendered hosted runtime timing summary"
        attachment.lifetime = .keepAlways
        add(attachment)

        XCTAssertLessThan(
            totalDuration,
            180,
            "Two rendered hosted rounds should complete without UI stalls"
        )
    }

    @MainActor
    func testRenderedHostedFlowPausesAtSummaryForMemoryGraphCapture() throws {
        let configuration = try memoryCaptureConfiguration()

        goToPlayerSetup()
        addMinimumPlayersIfNeeded()

        app.buttons[UITestAccessibilityIDs.startGameButton].tap()

        for round in 1...2 {
            waitForElement(identifier: UITestAccessibilityIDs.roleRevealScreen, timeout: 5)
            playCurrentRoundToSummary(playerCount: 3)

            if round < 2 {
                tapButtonWithScrolling(identifier: UITestAccessibilityIDs.playAgainButton, timeout: 5)
            }
        }

        try writeMemoryCaptureMarker(configuration.readyFile)
        Thread.sleep(forTimeInterval: configuration.pauseSeconds)
    }

    @MainActor
    func testMaximumPlayerRenderedFlowCompletesRound() throws {
        goToPlayerSetup()
        addPlayersIfNeeded(targetCount: 10)

        tapButtonWithScrolling(identifier: UITestAccessibilityIDs.startGameButton, timeout: 5)
        waitForElement(identifier: UITestAccessibilityIDs.roleRevealScreen, timeout: 5)

        let roundStart = Date()
        playCurrentRoundToSummary(playerCount: 10)
        let roundDuration = Date().timeIntervalSince(roundStart)

        let summary = """
        Maximum-player rendered flow lab
        Players: 10
        Round duration: \(String(format: "%.3f", roundDuration)) seconds
        Device: \(UIDevice.current.name)
        """
        let attachment = XCTAttachment(string: summary)
        attachment.name = "Maximum-player rendered flow timing summary"
        attachment.lifetime = .keepAlways
        add(attachment)

        XCTAssertLessThan(
            roundDuration,
            240,
            "A rendered 10-player round should complete without UI stalls"
        )
    }

    @MainActor
    func testPassAndPlayHandoffsDoNotExposeSecretWord() throws {
        goToPlayerSetup()
        addMinimumPlayersIfNeeded()

        app.buttons[UITestAccessibilityIDs.startGameButton].tap()
        waitForElement(identifier: UITestAccessibilityIDs.roleHandoffPrompt, timeout: 5)
        assertSecretWordHidden()

        revealOneRole()
        waitForElement(identifier: UITestAccessibilityIDs.roleHandoffPrompt, timeout: 5)
        assertSecretWordHidden()

        revealRoles(playerCount: 2)
        waitForElement(identifier: UITestAccessibilityIDs.clueRoundScreen, timeout: 5)
        slideToStartDiscussion()

        waitForElement(identifier: UITestAccessibilityIDs.discussionScreen, timeout: 5)
        app.buttons[UITestAccessibilityIDs.startVotingButton].tap()

        waitForElement(identifier: UITestAccessibilityIDs.votingScreen, timeout: 5)
        let voteButtons = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Vote for")
        )
        let firstVoteButton = voteButtons.element(boundBy: 0)
        XCTAssertTrue(firstVoteButton.waitForExistence(timeout: 5))
        firstVoteButton.tap()

        waitForElement(identifier: UITestAccessibilityIDs.voteHandoffPrompt, timeout: 5)
        assertSecretWordHidden()
        XCTAssertFalse(voteButtons.element(boundBy: 0).exists)
    }

    @MainActor
    func testRoleCardsHideSensitiveTextFromAccessibilityTree() throws {
        goToPlayerSetup()
        addMinimumPlayersIfNeeded()

        app.buttons[UITestAccessibilityIDs.startGameButton].tap()
        waitForElement(identifier: UITestAccessibilityIDs.roleHandoffPrompt, timeout: 5)

        for _ in 0..<3 {
            revealCurrentRoleWithoutContinuing()
            assertRoleCardAccessibilityIsSanitized()

            let continueHint = app.staticTexts["Tap anywhere to continue"]
            XCTAssertTrue(continueHint.waitForExistence(timeout: 5))
            continueHint.tap()
        }

        waitForElement(identifier: UITestAccessibilityIDs.clueRoundScreen, timeout: 5)
    }

    @MainActor
    func testForcedPrivacyShieldCoversInGameState() throws {
        relaunch(arguments: ["-ui-testing", "-ui-testing-force-privacy-shield"])
        goToPlayerSetup()
        addMinimumPlayersIfNeeded()

        app.buttons[UITestAccessibilityIDs.startGameButton].tap()
        let shield = app.descendants(matching: .any)[UITestAccessibilityIDs.privacyShield]
        XCTAssertTrue(shield.waitForExistence(timeout: 5))
        XCTAssertEqual(shield.label, "Private game hidden. Return to Imposter to continue.")


        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "Forced privacy shield covers in-game state"
        attachment.lifetime = .keepAlways
        add(attachment)

        assertSecretWordHidden()
    }

    @MainActor
    func testReducedMotionAndTransparencyKeepPrivateSurfacesUsable() throws {
        relaunch(arguments: ["-ui-testing", "-ui-testing-reduce-motion", "-ui-testing-reduce-transparency"])
        assertAccessibilityPreferencesStatus(
            "Reduce Motion enabled. Reduce Transparency enabled."
        )

        goToPlayerSetup()
        addMinimumPlayersIfNeeded()

        app.buttons[UITestAccessibilityIDs.startGameButton].tap()
        waitForElement(identifier: UITestAccessibilityIDs.roleHandoffPrompt, timeout: 5)
        assertSecretWordHidden()

        revealCurrentRoleWithoutContinuing()
        assertRoleCardAccessibilityIsSanitized()

        let continueHint = app.staticTexts["Tap anywhere to continue"]
        XCTAssertTrue(continueHint.waitForExistence(timeout: 5))
        continueHint.tap()
        waitForElement(identifier: UITestAccessibilityIDs.roleHandoffPrompt, timeout: 5)
        assertSecretWordHidden()

        relaunch(arguments: [
            "-ui-testing",
            "-ui-testing-reduce-motion",
            "-ui-testing-reduce-transparency",
            "-ui-testing-force-privacy-shield"
        ])
        assertAccessibilityPreferencesStatus(
            "Reduce Motion enabled. Reduce Transparency enabled."
        )
        goToPlayerSetup()
        addMinimumPlayersIfNeeded()

        app.buttons[UITestAccessibilityIDs.startGameButton].tap()
        let shield = app.descendants(matching: .any)[UITestAccessibilityIDs.privacyShield]
        XCTAssertTrue(shield.waitForExistence(timeout: 5))
        XCTAssertEqual(shield.label, "Private game hidden. Return to Imposter to continue.")
        assertSecretWordHidden()
    }

    @MainActor
    func testReducedTransparencyGameplaySurfacesReachSummary() throws {
        relaunch(arguments: ["-ui-testing", "-ui-testing-reduce-transparency"])
        assertAccessibilityPreferencesStatus(
            "Reduce Motion disabled. Reduce Transparency enabled."
        )

        goToPlayerSetup()
        addMinimumPlayersIfNeeded()
        dismissKeyboardIfVisible()
        captureScreenshot(named: "Reduced transparency player setup")

        tapButtonWithScrolling(identifier: UITestAccessibilityIDs.startGameButton, timeout: 5)
        waitForElement(identifier: UITestAccessibilityIDs.roleRevealScreen, timeout: 5)
        revealRoles(playerCount: 3)

        waitForElement(identifier: UITestAccessibilityIDs.clueRoundScreen, timeout: 5)
        slideToStartDiscussion()

        waitForElement(identifier: UITestAccessibilityIDs.discussionScreen, timeout: 5)
        app.buttons[UITestAccessibilityIDs.startVotingButton].tap()

        waitForElement(identifier: UITestAccessibilityIDs.votingScreen, timeout: 5)
        captureScreenshot(named: "Reduced transparency voting")
        castVotes(playerCount: 3)

        waitForElement(identifier: UITestAccessibilityIDs.revealScreen, timeout: 5)
        captureScreenshot(named: "Reduced transparency reveal")
        tapButtonWithScrolling(identifier: UITestAccessibilityIDs.continueToSummaryButton, timeout: 8)

        waitForElement(identifier: UITestAccessibilityIDs.summaryView, timeout: 5)
        captureScreenshot(named: "Reduced transparency summary")
        assertAccessibilityPreferencesStatus(
            "Reduce Motion disabled. Reduce Transparency enabled."
        )
    }

    // MARK: - Performance Tests

    @MainActor
    func testLaunchPerformance() throws {
        let options = XCTMeasureOptions()
        options.iterationCount = 5
        var wallClockDurations: [TimeInterval] = []

        measure(metrics: [XCTApplicationLaunchMetric()], options: options) {
            let measuredApp = XCUIApplication()
            measuredApp.launchArguments = ["-ui-testing"]
            let launchStart = ProcessInfo.processInfo.systemUptime
            measuredApp.launch()
            XCTAssertTrue(measuredApp.staticTexts[UITestAccessibilityIDs.homeTitle].waitForExistence(timeout: 6))
            wallClockDurations.append(ProcessInfo.processInfo.systemUptime - launchStart)
        }

        let sortedDurations = wallClockDurations.sorted()
        let averageDuration = wallClockDurations.reduce(0, +) / Double(max(wallClockDurations.count, 1))
        let medianDuration = sortedDurations[sortedDurations.count / 2]
        let maxDuration = sortedDurations.last ?? 0
        let slowReadinessCount = wallClockDurations.filter { $0 > 8 }.count

        let summary = """
        Launch performance UI-readiness envelope
        Iterations: \(wallClockDurations.count)
        Durations: \(wallClockDurations.map { String(format: "%.3f", $0) }.joined(separator: ", ")) seconds
        Average: \(String(format: "%.3f", averageDuration)) seconds
        Median: \(String(format: "%.3f", medianDuration)) seconds
        Max: \(String(format: "%.3f", maxDuration)) seconds
        UI-readiness launches over 8s: \(slowReadinessCount)
        Device: \(UIDevice.current.name)
        """
        let attachment = XCTAttachment(string: summary)
        attachment.name = "Launch performance UI-readiness envelope"
        attachment.lifetime = .keepAlways
        add(attachment)

        XCTAssertLessThan(
            medianDuration,
            6,
            "Median XCUITest UI readiness should stay responsive; the Xcode AppLaunch metric remains the launch-duration source of truth"
        )
        XCTAssertLessThanOrEqual(
            slowReadinessCount,
            0,
            "Repeated XCUITest readiness outliers indicate more than simulator noise"
        )
    }

    // MARK: - Helpers

    private var shouldLaunchAppInSetUp: Bool {
        !name.contains("testLaunchPerformance")
    }

    private func launchApp(arguments: [String] = ["-ui-testing"]) {
        app.launchArguments = arguments
        app.launch()
    }

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

    @MainActor
    private func relaunch(arguments: [String]) {
        app.terminate()
        app = XCUIApplication()
        launchApp(arguments: arguments)
    }

    @MainActor
    private func addMinimumPlayersIfNeeded() {
        addPlayersIfNeeded(targetCount: 3)
    }

    @MainActor
    private func addPlayersIfNeeded(
        targetCount: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue((3...10).contains(targetCount), "Target count must be within the playable player range", file: file, line: line)

        var count = currentPlayerCount(file: file, line: line)
        XCTAssertLessThanOrEqual(count, targetCount, "Setup already has more players than requested", file: file, line: line)

        while count < targetCount {
            tapAddPlayerButton(file: file, line: line)
            count += 1
            waitForPlayerCount(count, file: file, line: line)
        }

        XCTAssertEqual(currentPlayerCount(file: file, line: line), targetCount, file: file, line: line)
        XCTAssertTrue(app.buttons[UITestAccessibilityIDs.startGameButton].isEnabled, file: file, line: line)
    }

    @MainActor
    private func tapAddPlayerButton(file: StaticString = #filePath, line: UInt = #line) {
        dismissKeyboardIfVisible()

        let addPlayerButton = app.buttons[UITestAccessibilityIDs.addPlayerButton]
        XCTAssertTrue(addPlayerButton.waitForExistence(timeout: 3), file: file, line: line)

        for _ in 0..<8 where !addPlayerButton.isHittable {
            app.swipeUp()
        }

        XCTAssertTrue(addPlayerButton.isHittable, "Add Player button was not hittable", file: file, line: line)
        addPlayerButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    @MainActor
    private func currentPlayerCount(file: StaticString = #filePath, line: UInt = #line) -> Int {
        let status = app.staticTexts[UITestAccessibilityIDs.setupSubtitle]
        XCTAssertTrue(status.waitForExistence(timeout: 3), "Setup subtitle is missing", file: file, line: line)

        guard
            let countText = status.label.split(separator: " ").first,
            let count = Int(countText)
        else {
            XCTFail("Could not parse player count from setup subtitle: \(status.label)", file: file, line: line)
            return -1
        }

        return count
    }

    @MainActor
    private func waitForPlayerCount(
        _ count: Int,
        timeout: TimeInterval = 3,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let status = app.staticTexts[UITestAccessibilityIDs.setupSubtitle]
        XCTAssertTrue(status.waitForExistence(timeout: 3), "Setup subtitle is missing", file: file, line: line)

        let expectedPrefix = "\(count) "
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label BEGINSWITH %@", expectedPrefix),
            object: status
        )
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, "Expected setup subtitle to start with '\(expectedPrefix)', got '\(status.label)'", file: file, line: line)
    }

    @MainActor
    private func dismissKeyboardIfVisible() {
        guard app.keyboards.element.exists else { return }

        let returnButton = app.keyboards.buttons["return"]
        let doneButton = app.keyboards.buttons["Done"]

        // Only tap a keyboard key when it is actually hittable. When the
        // simulator has a hardware keyboard attached, the software keyboard's
        // return key can be reported as existing while sitting offscreen, so
        // tap() fails with a scroll-to-visible error. In that case dismiss the
        // keyboard by tapping a neutral area instead of depending on key geometry.
        if returnButton.exists && returnButton.isHittable {
            returnButton.tap()
        } else if doneButton.exists && doneButton.isHittable {
            doneButton.tap()
        } else {
            let neutralPoint = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08))
            neutralPoint.tap()
        }
    }

    @MainActor
    private func captureScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    private func revealRoles(playerCount: Int) {
        for _ in 0..<playerCount {
            revealOneRole()
        }
    }

    @MainActor
    private func playCurrentRoundToSummary(playerCount: Int) {
        revealRoles(playerCount: playerCount)

        waitForElement(identifier: UITestAccessibilityIDs.clueRoundScreen, timeout: 5)
        slideToStartDiscussion()

        waitForElement(identifier: UITestAccessibilityIDs.discussionScreen, timeout: 5)
        app.buttons[UITestAccessibilityIDs.startVotingButton].tap()

        waitForElement(identifier: UITestAccessibilityIDs.votingScreen, timeout: 5)
        castVotes(playerCount: playerCount)

        waitForElement(identifier: UITestAccessibilityIDs.revealScreen, timeout: 5)
        tapButtonWithScrolling(identifier: UITestAccessibilityIDs.continueToSummaryButton, timeout: 8)

        waitForElement(identifier: UITestAccessibilityIDs.summaryView, timeout: 5)
    }

    @MainActor
    private func revealOneRole() {
        revealCurrentRoleWithoutContinuing()

        let continueHint = app.staticTexts["Tap anywhere to continue"]
        XCTAssertTrue(continueHint.waitForExistence(timeout: 5))
        continueHint.tap()
    }

    @MainActor
    private func revealCurrentRoleWithoutContinuing() {
        let revealButton = app.descendants(matching: .any)[UITestAccessibilityIDs.revealRoleButton]
        XCTAssertTrue(revealButton.waitForExistence(timeout: 5))
        revealButton.press(forDuration: 0.8)

        waitForElement(identifier: UITestAccessibilityIDs.roleCard, timeout: 5)
        let continueHint = app.staticTexts["Tap anywhere to continue"]
        XCTAssertTrue(continueHint.waitForExistence(timeout: 5))
    }

    @MainActor
    private func slideToStartDiscussion() {
        let slider = app.descendants(matching: .any)[UITestAccessibilityIDs.startDiscussionSlider]
        XCTAssertTrue(slider.waitForExistence(timeout: 5))

        let start = slider.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5))
        let end = slider.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: end)
    }

    @MainActor
    private func castVotes(playerCount: Int) {
        for index in 0..<playerCount {
            let voteButtons = app.buttons.matching(
                NSPredicate(format: "label BEGINSWITH %@", "Vote for")
            )
            let voteButton = voteButtons.element(boundBy: 0)

            XCTAssertTrue(voteButton.waitForExistence(timeout: 5))
            voteButton.tap()

            if index < playerCount - 1 {
                XCTAssertTrue(app.staticTexts["Vote Recorded!"].waitForExistence(timeout: 5))
                let continueHint = app.staticTexts["Tap anywhere to continue"]
                XCTAssertTrue(continueHint.waitForExistence(timeout: 5))
                continueHint.tap()
            }
        }
    }

    @MainActor
    private func tapButtonWithScrolling(identifier: String, timeout: TimeInterval) {
        let button = app.buttons[identifier]
        XCTAssertTrue(button.waitForExistence(timeout: timeout))

        for _ in 0..<5 where !button.isHittable {
            app.swipeUp()
        }

        XCTAssertTrue(button.isHittable)
        button.tap()
    }

    @MainActor
    private func waitForElement(identifier: String, timeout: TimeInterval) {
        let element = app.descendants(matching: .any)[identifier]
        XCTAssertTrue(element.waitForExistence(timeout: timeout))
    }

    @MainActor
    private func assertSecretWordHidden(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertFalse(app.staticTexts["Elephant"].exists, "Secret word text appeared during a handoff screen", file: file, line: line)
        XCTAssertFalse(
            app.descendants(matching: .any)[UITestAccessibilityIDs.secretWordDisplay].exists,
            "Sensitive secret word display appeared during a handoff screen",
            file: file,
            line: line
        )
    }

    @MainActor
    private func assertRoleCardAccessibilityIsSanitized(file: StaticString = #filePath, line: UInt = #line) {
        let roleCard = app.descendants(matching: .any)[UITestAccessibilityIDs.roleCard]
        XCTAssertTrue(roleCard.exists, "Role card accessibility container is missing", file: file, line: line)
        XCTAssertTrue(
            roleCard.label.hasPrefix("Private role card"),
            "Role card should expose only a sanitized privacy label, got: \(roleCard.label)",
            file: file,
            line: line
        )

        let forbiddenLabels = [
            "Elephant",
            "THE SECRET WORD",
            "INFORMED",
            "IMPOSTER",
            "HINT",
            "Animals"
        ]

        for label in forbiddenLabels {
            XCTAssertFalse(
                app.staticTexts[label].exists,
                "Sensitive role text '\(label)' appeared in the accessibility tree",
                file: file,
                line: line
            )
            XCTAssertFalse(
                roleCard.label.localizedCaseInsensitiveContains(label),
                "Sanitized role card label leaked sensitive text '\(label)'",
                file: file,
                line: line
            )
        }

        XCTAssertFalse(
            app.descendants(matching: .any)[UITestAccessibilityIDs.secretWordDisplay].exists,
            "Secret word display should not be exposed while the private role card is visible",
            file: file,
            line: line
        )
    }

    @MainActor
    private func assertAccessibilityPreferencesStatus(
        _ expectedLabel: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let status = app.descendants(matching: .any)[UITestAccessibilityIDs.accessibilityPreferencesStatus]
        XCTAssertTrue(status.waitForExistence(timeout: 3), "Accessibility preferences status marker is missing", file: file, line: line)
        XCTAssertEqual(status.label, expectedLabel, file: file, line: line)
    }

    private struct MemoryCaptureConfiguration {
        let readyFile: String
        let pauseSeconds: TimeInterval
    }

    private func memoryCaptureConfiguration() throws -> MemoryCaptureConfiguration {
        let controlPath = "/tmp/imposter-memory-capture-control"
        guard FileManager.default.fileExists(atPath: controlPath) else {
            throw XCTSkip("Create \(controlPath) to run this external memgraph capture helper.")
        }

        let content = try String(contentsOfFile: controlPath, encoding: .utf8)
        let values = Dictionary(
            uniqueKeysWithValues: content
                .split(whereSeparator: \.isNewline)
                .compactMap { line -> (String, String)? in
                    let parts = line.split(separator: "=", maxSplits: 1).map(String.init)
                    guard parts.count == 2 else { return nil }
                    return (parts[0], parts[1])
                }
        )

        let readyFile = values["ready_file"] ?? "/tmp/imposter-memory-capture-ready"
        let pauseSeconds = TimeInterval(values["pause_seconds"] ?? "90") ?? 90

        return MemoryCaptureConfiguration(
            readyFile: readyFile,
            pauseSeconds: max(pauseSeconds, 1)
        )
    }

    private func writeMemoryCaptureMarker(_ path: String) throws {
        let marker = """
        ready
        test=\(name)
        """

        try marker.write(toFile: path, atomically: true, encoding: .utf8)
    }
}

private enum UITestAccessibilityIDs {
    static let homeTitle = "homeTitle"
    static let newGameButton = "newGameButton"
    static let addPlayerButton = "addPlayerButton"
    static let startGameButton = "startGameButton"
    static let setupSubtitle = "setupSubtitle"
    static let categoryContinueButton = "categoryContinueButton"
    static let roleRevealScreen = "roleRevealScreen"
    static let privacyShield = "privacyShield"
    static let roleHandoffPrompt = "roleHandoffPrompt"
    static let revealRoleButton = "revealRoleButton"
    static let roleCard = "roleCard"
    static let secretWordDisplay = "secretWordDisplay"
    static let accessibilityPreferencesStatus = "accessibilityPreferencesStatus"
    static let clueRoundScreen = "clueRoundScreen"
    static let startDiscussionSlider = "startDiscussionSlider"
    static let discussionScreen = "discussionScreen"
    static let startVotingButton = "startVotingButton"
    static let votingScreen = "votingScreen"
    static let voteHandoffPrompt = "voteHandoffPrompt"
    static let revealScreen = "revealScreen"
    static let continueToSummaryButton = "continueToSummaryButton"
    static let summaryView = "summaryView"
    static let playAgainButton = "playAgainButton"
}
