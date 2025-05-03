//
//  AnimationToggle.swift
//  Speed2048
//
//  Created by Lucas Longo on 4/22/25.
//

import SwiftUI

struct AnimationSpeedToggle: View {
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        HStack(alignment: .center)  {
            Spacer()
            Toggle(isOn: $gameManager.fastAnimations) {
                Label("Fast Animations?", systemImage: "hare")
                    .bold()
            }
            .padding(.horizontal, 5)
            Spacer()
        }
        .foregroundStyle(gameManager.fontColor)
    }
}

