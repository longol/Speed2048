//
//  BoardSizePicker.swift
//  Speed2048
//
//  Created by Lucas Longo on 4/22/25.
//

import SwiftUI

struct BoardSizePicker: View {
    @ObservedObject var gameManager: GameManager
    var showTitle = true

    var body: some View {
        VStack(alignment: .leading) {
            if showTitle {
                Text("Board Size").bold()
            }

            HStack {
                Text("4x4")
                Slider(value: Binding(
                    get: { Double(gameManager.boardSize) },
                    set: { gameManager.boardSize = Int($0) }
                ), in: 4...10, step: 1)
                Text("10x10")
            }
            
            HStack {
                Spacer()
                Text("\(gameManager.boardSize)x\(gameManager.boardSize)")
                    .font(.headline)
                Spacer()
            }
            
            if showTitle {
                HStack {
                    Spacer()
                    Text("Changing board size will start a new game")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                }
            }
        }
    }
}
