//
//  Quest131072App.swift
//  Quest131072
//
//  Created by Lucas Longo on 2/22/25.
//

import SwiftUI

@main
struct Quest131072App: App {
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
