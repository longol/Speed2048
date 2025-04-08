//
//  Quest131072WatchApp.swift
//  Quest131072Watch Watch App
//
//  Created by Lucas Longo on 4/7/25.
//

import SwiftUI

@main
struct Quest131072Watch_Watch_AppApp: App {
    @StateObject private var gameModel = GameViewModel()
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView(gameModel: gameModel)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background || newPhase == .inactive {
                gameModel.saveGameState()
            } else if newPhase == .active {
                gameModel.checkCloudVersion()
            }
        }
    }
}
