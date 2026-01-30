//
//  GamePhaseTests.swift
//  ImposterTests
//
//  Unit tests for GamePhase state machine transitions.
//

import Testing
@testable import Imposter

@Suite("Game Phase Tests")
@MainActor
struct GamePhaseTests {

    // MARK: - Valid Transition Tests

    @Test func setupCanTransitionToRoleReveal() {
        #expect(GamePhase.setup.canTransition(to: .roleReveal))
    }

    @Test func roleRevealCanTransitionToClueRound() {
        #expect(GamePhase.roleReveal.canTransition(to: .clueRound))
    }

    @Test func clueRoundCanTransitionToDiscussion() {
        #expect(GamePhase.clueRound.canTransition(to: .discussion))
    }

    @Test func clueRoundCanTransitionToVoting() {
        #expect(GamePhase.clueRound.canTransition(to: .voting))
    }

    @Test func discussionCanTransitionToVoting() {
        #expect(GamePhase.discussion.canTransition(to: .voting))
    }

    @Test func votingCanTransitionToReveal() {
        #expect(GamePhase.voting.canTransition(to: .reveal))
    }

    @Test func revealCanTransitionToSummary() {
        #expect(GamePhase.reveal.canTransition(to: .summary))
    }

    @Test func summaryCanTransitionToRoleReveal() {
        #expect(GamePhase.summary.canTransition(to: .roleReveal))
    }

    @Test func summaryCanTransitionToSetup() {
        #expect(GamePhase.summary.canTransition(to: .setup))
    }

    // MARK: - Invalid Transition Tests

    @Test func setupCannotSkipToClueRound() {
        #expect(!GamePhase.setup.canTransition(to: .clueRound))
    }

    @Test func setupCannotSkipToVoting() {
        #expect(!GamePhase.setup.canTransition(to: .voting))
    }

    @Test func roleRevealCannotGoBackToSetup() {
        #expect(!GamePhase.roleReveal.canTransition(to: .setup))
    }

    @Test func clueRoundCannotGoBackToRoleReveal() {
        #expect(!GamePhase.clueRound.canTransition(to: .roleReveal))
    }

    @Test func votingCannotGoBackToClueRound() {
        #expect(!GamePhase.voting.canTransition(to: .clueRound))
    }

    @Test func revealCannotGoBackToVoting() {
        #expect(!GamePhase.reveal.canTransition(to: .voting))
    }

    @Test func discussionCannotSkipToReveal() {
        #expect(!GamePhase.discussion.canTransition(to: .reveal))
    }

    // MARK: - Complete Path Tests

    @Test func allPhasesHaveValidPath() {
        // Test complete game flow path
        let phases: [GamePhase] = [.setup, .roleReveal, .clueRound, .voting, .reveal, .summary]

        for i in 0..<(phases.count - 1) {
            let current = phases[i]
            let next = phases[i + 1]
            #expect(current.canTransition(to: next), "Expected \(current) to transition to \(next)")
        }
    }

    @Test func gameFlowWithDiscussion() {
        // Test flow that includes discussion phase
        let phases: [GamePhase] = [.setup, .roleReveal, .clueRound, .discussion, .voting, .reveal, .summary]

        for i in 0..<(phases.count - 1) {
            let current = phases[i]
            let next = phases[i + 1]
            #expect(current.canTransition(to: next), "Expected \(current) to transition to \(next)")
        }
    }

    @Test func summaryCanStartNewRound() {
        // New round: summary -> roleReveal (skipping setup)
        #expect(GamePhase.summary.canTransition(to: .roleReveal))
    }

    // MARK: - Self Transition Tests

    @Test func phasesCannotTransitionToSelf() {
        for phase in GamePhase.allCases {
            #expect(!phase.canTransition(to: phase), "\(phase) should not transition to itself")
        }
    }
}
