//
//  GeneratedWordPolicyTests.swift
//  ImposterTests
//
//  Tests for deterministic AI word-response guardrails.
//

import XCTest
@testable import Imposter

@MainActor
final class GeneratedWordPolicyTests: XCTestCase {

    func testValidateRemovesPrefixQuotesAndPunctuation() throws {
        let result = GeneratedWordPolicy.validate(
            rawResponse: "Related word: \"red panda.\"",
            prompt: "zoo animals"
        )

        XCTAssertEqual(try result.get(), "Red Panda")
    }

    func testValidateUsesFirstNonEmptyLine() throws {
        let result = GeneratedWordPolicy.validate(
            rawResponse: "\n\n- Lantern\nA glowing object",
            prompt: "camping"
        )

        XCTAssertEqual(try result.get(), "Lantern")
    }

    func testValidateRejectsPromptEchoAndNearDuplicate() {
        let result = GeneratedWordPolicy.validate(
            rawResponse: "Ocean creature",
            prompt: "Ocean creatures"
        )

        XCTAssertEqual(result.failure, .promptEcho)
    }

    func testValidateRejectsSentenceLikeResponse() {
        let result = GeneratedWordPolicy.validate(
            rawResponse: "Here is a good word: dolphin",
            prompt: "ocean"
        )

        XCTAssertEqual(result.failure, .sentenceLike)
    }

    func testValidateKeepsNumberedNounsThatAreNotListMarkers() throws {
        let result = GeneratedWordPolicy.validate(
            rawResponse: "3D Printer",
            prompt: "technology"
        )

        XCTAssertEqual(try result.get(), "3D Printer")
    }
}

private extension Result where Failure == GeneratedWordPolicy.Rejection {
    var failure: Failure? {
        guard case .failure(let failure) = self else {
            return nil
        }
        return failure
    }
}
