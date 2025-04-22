//
//  AnimationToggle.swift
//  Speed2048
//
//  Created by Lucas Longo on 4/22/25.
//

import SwiftUI

struct AnimationSpeedToggle: View {
    @ObservedObject var gameManager: GameManager
    var showTitle = true
    
    var body: some View {
        VStack(alignment: .leading) {
            if showTitle {
                Text("Animation Levels").bold()
            }
            Toggle(isOn: $gameManager.fastAnimations) {
                Label("Fast animations?", systemImage: "hare")
            }
            .padding()
        }
    }
}

