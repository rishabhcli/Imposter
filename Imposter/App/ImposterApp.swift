//
//  ImposterApp.swift
//  Imposter
//
//  Main entry point for the Imposter party game.
//

import SwiftUI

@main
struct ImposterApp: App {
    @State private var appEnvironment: AppEnvironment
    @State private var gameStore: GameStore

    init() {
        let appEnvironment = AppEnvironment.live()
        _appEnvironment = State(initialValue: appEnvironment)
        _gameStore = State(initialValue: appEnvironment.makeGameStore())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(gameStore)
                .environment(\.appEnvironment, appEnvironment)
        }
    }
}
