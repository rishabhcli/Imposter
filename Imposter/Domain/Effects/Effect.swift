//
//  Effect.swift
//  Imposter
//
//  Effect type for handling side effects in a pure functional way.
//  Reducers return Effects to describe side effects without executing them.
//

import Foundation

// MARK: - Effect

/// Represents a side effect that can be performed after a state change.
/// Effects are returned by the reducer and executed by the store.
enum Effect: Sendable {

    /// No side effect
    case none

    /// Run an async operation that may return a follow-up action
    case run(@Sendable () async -> GameAction?)

    /// Run an async operation that may throw, with error handling
    case runWithError(
        work: @Sendable () async throws -> GameAction?,
        onError: @Sendable (Error) -> GameAction
    )

    /// Run multiple effects in parallel
    case batch([Effect])

    /// Run multiple effects sequentially
    case sequence([Effect])

    /// Cancel a specific effect by ID (for future use)
    case cancel(id: String)
}

// MARK: - Convenience Initializers

extension Effect {

    /// Creates an effect that runs async work without returning an action
    static func fireAndForget(_ work: @escaping @Sendable () async -> Void) -> Effect {
        .run {
            await work()
            return nil
        }
    }

    /// Creates an effect that dispatches an action after a delay
    static func delayed(
        _ action: GameAction,
        by duration: Duration
    ) -> Effect {
        .run {
            try? await Task.sleep(for: duration)
            return action
        }
    }

    /// Creates an effect that generates a word from the given settings
    static func generateWord(
        source: GameSettings.WordSource,
        categories: [String]?,
        difficulty: GameSettings.Difficulty,
        customPrompt: String?
    ) -> Effect {
        .runWithError(
            work: {
                // This will be replaced with actual service call in Phase 2
                return nil
            },
            onError: { error in
                .wordGenerationFailed(GameActionError(error))
            }
        )
    }

    /// Creates an effect that generates an image for a word
    static func generateImage(
        for word: String,
        category: String
    ) -> Effect {
        .runWithError(
            work: {
                // This will be replaced with actual service call in Phase 2
                return nil
            },
            onError: { error in
                .imageGenerationFailed(GameActionError(error))
            }
        )
    }

    /// Creates an effect that persists the current state
    static func persist(_ state: GameState) -> Effect {
        .fireAndForget {
            // This will be replaced with actual service call in Phase 2
        }
    }

    /// Creates an effect that plays a haptic
    static func haptic(_ type: HapticEffect) -> Effect {
        .fireAndForget {
            // This will be replaced with actual service call in Phase 2
        }
    }
}

// MARK: - Effect Composition

extension Effect {

    /// Combines this effect with another to run in parallel
    func and(_ other: Effect) -> Effect {
        switch (self, other) {
        case (.none, .none):
            return .none
        case (.none, _):
            return other
        case (_, .none):
            return self
        case (.batch(let effects1), .batch(let effects2)):
            return .batch(effects1 + effects2)
        case (.batch(let effects), _):
            return .batch(effects + [other])
        case (_, .batch(let effects)):
            return .batch([self] + effects)
        default:
            return .batch([self, other])
        }
    }

    /// Chains this effect with another to run sequentially
    func then(_ other: Effect) -> Effect {
        switch (self, other) {
        case (.none, .none):
            return .none
        case (.none, _):
            return other
        case (_, .none):
            return self
        case (.sequence(let effects1), .sequence(let effects2)):
            return .sequence(effects1 + effects2)
        case (.sequence(let effects), _):
            return .sequence(effects + [other])
        case (_, .sequence(let effects)):
            return .sequence([self] + effects)
        default:
            return .sequence([self, other])
        }
    }
}

// MARK: - Effect Inspection

extension Effect {

    /// Whether this effect is `.none`
    var isNone: Bool {
        if case .none = self { return true }
        return false
    }

    /// Whether this effect is a `.run` effect
    var isRun: Bool {
        if case .run = self { return true }
        return false
    }

    /// Whether this effect is a `.runWithError` effect
    var isRunWithError: Bool {
        if case .runWithError = self { return true }
        return false
    }

    /// Whether this effect is a `.batch` effect
    var isBatch: Bool {
        if case .batch = self { return true }
        return false
    }

    /// Whether this effect is a `.sequence` effect
    var isSequence: Bool {
        if case .sequence = self { return true }
        return false
    }
}

// MARK: - HapticEffect

/// Types of haptic effects that can be triggered
enum HapticEffect: Sendable {
    case buttonTap
    case clueSubmitted
    case voteSelected
    case gameStarted
    case roundCompleted
    case imposterCaught
    case imposterEscaped
    case selection
}

// MARK: - Effect Runner

/// Executes effects and dispatches resulting actions
@MainActor
struct EffectRunner {

    /// The dispatch function to send resulting actions
    let dispatch: (GameAction) -> Void

    /// Runs an effect, potentially dispatching follow-up actions
    func run(_ effect: Effect) async {
        switch effect {
        case .none:
            break

        case .run(let work):
            if let action = await work() {
                dispatch(action)
            }

        case .runWithError(let work, let onError):
            do {
                if let action = try await work() {
                    dispatch(action)
                }
            } catch {
                dispatch(onError(error))
            }

        case .batch(let effects):
            await withTaskGroup(of: Void.self) { group in
                for effect in effects {
                    group.addTask {
                        await self.run(effect)
                    }
                }
            }

        case .sequence(let effects):
            for effect in effects {
                await run(effect)
            }

        case .cancel:
            // Future: implement cancellation
            break
        }
    }
}
