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
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                Label("Board Size", systemImage: "square.grid.3x3")
                    .bold()
                
                Spacer()
                
                Stepper("\(gameManager.boardSize)x\(gameManager.boardSize)",
                        value: $gameManager.boardSize,
                        in: 4...10,
                        step: 1)
                .padding(5)
            }
        }
    }
}
