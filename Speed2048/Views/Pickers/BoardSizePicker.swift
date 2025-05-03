//
//  BoardSizePicker.swift
//  Speed2048
//
//  Created by Lucas Longo on 4/22/25.
//

import SwiftUI

struct BoardSizePicker: View {
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        HStack(alignment: .center) {
            Spacer()

            Label("Board size \(gameManager.boardSize)x\(gameManager.boardSize)", systemImage: "square.grid.3x3")
                .bold()
                    
            Stepper("",
                    value: $gameManager.boardSize,
                    in: 4...10,
                    step: 1)
            .padding(5)

            Spacer()
        }
        .foregroundStyle(gameManager.fontColor)
    }
}
