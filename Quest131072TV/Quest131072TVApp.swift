//
//  Quest131072TVApp.swift
//  Quest131072TV
//
//  Created by Lucas Longo on 4/5/25.
//

import SwiftUI

@main
struct Quest131072TVApp: App {
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
