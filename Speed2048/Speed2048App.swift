//
//  Speed2048App.swift
//  Speed2048
//
//  Created by Lucas Longo on 2/22/25.
//

import SwiftUI

@main
struct Speed2048App: App {
    @StateObject private var gameManager = GameManager()
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameManager)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background || newPhase == .inactive {
                Task {
                    await gameManager.saveGameState()
                }
            } else if newPhase == .active {
                Task {
                    await gameManager.checkCloudVersion()
                }
            }
        }
    }
}

