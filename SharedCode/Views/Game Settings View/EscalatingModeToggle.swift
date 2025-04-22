//
//  EscalatingModeToggle.swift
//  Speed2048
//
//  Created by Lucas Longo on 4/22/25.
//

import SwiftUI

struct EscalatingModeToggle: View {
    @ObservedObject var gameManager: GameManager
    var showTitle = true

    var body: some View {
        VStack(alignment: .leading) {
            if showTitle {
                Text("Game Modes").bold()
            }

            Toggle(isOn: $gameManager.escalatingMode) {
                Label("Escalating Tiles", systemImage: "arrow.up.forward")
            }
            .padding()
            
            if showTitle {
                Text("In escalating mode, when no more 2s remain, you'll start getting 4s and 8s. When no more 4s remain, you'll start getting 8s and 16s, and so on.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            }
        }
    }
}
