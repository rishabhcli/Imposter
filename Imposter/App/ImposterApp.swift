//
//  ImposterApp.swift
//  Imposter
//
//  Main entry point for the Imposter party game.
//

import SwiftUI

@main
struct ImposterApp: App {
    /// The central game store, injected into the environment
    @State private var gameStore = GameStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(gameStore)
        }
    }
}
