//
//  HapticsServiceTests.swift
//  ImposterTests
//
//  Unit tests for HapticsService implementation.
//

import XCTest
@testable import Imposter

@MainActor
final class HapticsServiceTests: XCTestCase {

    var sut: HapticsService!

    override func setUp() {
        super.setUp()
        sut = HapticsService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Impact Feedback Tests

    func testPlayImpact_Light_DoesNotCrash() {
        // This test verifies the method doesn't crash
        // Actual haptic feedback can't be tested in unit tests
        sut.playImpact(.light)
    }

    func testPlayImpact_Medium_DoesNotCrash() {
        sut.playImpact(.medium)
    }

    func testPlayImpact_Heavy_DoesNotCrash() {
        sut.playImpact(.heavy)
    }

    func testPlayImpact_Soft_DoesNotCrash() {
        sut.playImpact(.soft)
    }

    func testPlayImpact_Rigid_DoesNotCrash() {
        sut.playImpact(.rigid)
    }

    // MARK: - Notification Feedback Tests

    func testPlayNotification_Success_DoesNotCrash() {
        sut.playNotification(.success)
    }

    func testPlayNotification_Warning_DoesNotCrash() {
        sut.playNotification(.warning)
    }

    func testPlayNotification_Error_DoesNotCrash() {
        sut.playNotification(.error)
    }

    // MARK: - Selection Feedback Tests

    func testPlaySelection_DoesNotCrash() {
        sut.playSelection()
    }

    // MARK: - Game-Specific Haptics Tests

    func testClueSubmitted_DoesNotCrash() {
        sut.clueSubmitted()
    }

    func testVoteSelected_DoesNotCrash() {
        sut.voteSelected()
    }

    func testImposterCaught_DoesNotCrash() {
        sut.imposterCaught()
    }

    func testImposterEscaped_DoesNotCrash() {
        sut.imposterEscaped()
    }

    func testButtonTap_DoesNotCrash() {
        sut.buttonTap()
    }

    func testGameStarted_DoesNotCrash() {
        sut.gameStarted()
    }

    func testRoundCompleted_DoesNotCrash() {
        sut.roundCompleted()
    }

    // MARK: - Prepare Tests

    func testPrepare_DoesNotCrash() {
        sut.prepare()
    }
}
