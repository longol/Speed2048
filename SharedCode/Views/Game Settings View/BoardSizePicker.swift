//
//  BoardSizePicker.swift
//  Speed2048
//
//  Created by Lucas Longo on 4/22/25.
//

import SwiftUI

struct BoardSizePicker: View {
    @EnvironmentObject var gameManager: GameManager
    var showTitle = true
    
    @State private var temporaryBoardSize: Int = 4
    
    init(showTitle: Bool = true) {
        self.showTitle = showTitle
    }

    var body: some View {
        VStack(alignment: .leading) {
            if showTitle {
                Text("Board Size").bold()
            }
            
            HStack {
                Text("4x4")
                Slider(
                    value: Binding(
                        get: { Double(temporaryBoardSize) },
                        set: { 
                            temporaryBoardSize = Int($0) 
                            gameManager.boardSize = temporaryBoardSize
                        }
                    ),
                    in: 4...10, 
                    step: 1
                )
                Text("10x10")
            }
            
            HStack {
                Spacer()
                Text("\(temporaryBoardSize)x\(temporaryBoardSize)")
                    .font(.headline)
                Spacer()
            }
            
            if showTitle {
                HStack {
                    Spacer()
                    Text("Tiles will be preserved when changing board size")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                }
            }
        }
        .padding()
        .onAppear {
            self.temporaryBoardSize = gameManager.boardSize
        }
        .onChange(of: gameManager.boardSize) { oldValue, newValue in
            self.temporaryBoardSize = gameManager.boardSize
        }
    }
}
