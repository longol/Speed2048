//
//  AnimationToggle.swift
//  Speed2048
//
//  Created by Lucas Longo on 4/22/25.
//

import SwiftUI

struct AnimationSpeedToggle: View {
    @EnvironmentObject var gameManager: GameManager
    var showTitle = true
    
    var body: some View {
        HStack {
            if showTitle {
                Text("Animation Levels").bold()
            }
            Toggle(isOn: $gameManager.fastAnimations) {
                Label("Fast animations?", systemImage: "hare")
            }
        }
        .padding()
    }
}

