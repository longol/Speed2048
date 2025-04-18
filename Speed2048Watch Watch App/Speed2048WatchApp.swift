//
//  Speed2048WatchApp.swift
//  Speed2048Watch Watch App
//
//  Created by Lucas Longo on 4/8/25.
//

import SwiftUI

@main
struct Speed2048Watch_Watch_AppApp: App {
    @StateObject private var gameManager = GameManager()
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView(gameManager: gameManager)
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
