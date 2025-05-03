//
//  GameBoardView.swift
//  Speed2048
//
//  Created by Lucas Longo on 5/3/25.
//

import SwiftUI

struct GameBoardView: View {
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        GeometryReader { geo in
            let side = geo.size.width
            let cellSize = side / CGFloat(gameManager.boardSize)
            ZStack {
                // Draw the background grid.
                ForEach(0..<gameManager.boardSize, id: \.self) { row in
                    ForEach(0..<gameManager.boardSize, id: \.self) { col in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: cellSize-2, height: cellSize-2)
                            .position(
                                x: CGFloat(col) * cellSize + cellSize/2,
                                y: CGFloat(row) * cellSize + cellSize/2
                            )
                    }
                }
                // Draw the tiles.
                ForEach(gameManager.tiles) { tile in
                    TileView(
                        tile: tile,
                        cellSize: cellSize,
                        isEditMode: gameManager.isEditMode,
                        themeColor: gameManager.baseButtonColor, // Change this from backgroundColor to baseButtonColor
                        onDelete: { id in
                            gameManager.deleteTile(id: id)
                        }
                    )
                }
                
            }
            .frame(width: side, height: side)
            .background(Color.gray.opacity(0.3))
            .cornerRadius(8)
            .background(KeyEventHandlingView { key in
                switch key {
                case .left:  gameManager.move(.left)
                case .right: gameManager.move(.right)
                case .up:    gameManager.move(.up)
                case .down:  gameManager.move(.down)
                }
            })
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        let horizontal = value.translation.width
                        let vertical = value.translation.height
                        let direction: Direction = (abs(horizontal) > abs(vertical)) ?
                        (horizontal > 0 ? .right : .left) :
                        (vertical > 0 ? .down : .up)
                        gameManager.move(direction)
                    }
            )
            .animation(.easeInOut(duration: 0.3), value: gameManager.showOverlayMessage)
        }
        .aspectRatio(1, contentMode: .fit)
        .padding()
        .layoutPriority(1)  // ensure the game board isn't squeezed by other views
    
    }
    
    @ViewBuilder private var keyboardShortcuts: some View {
        Group {
            Button("") {
                Task {
                    await gameManager.saveGameState()
                }
            }
            .keyboardShortcut("s", modifiers: .command)
            
            Button("") {
                Task {
                    await gameManager.checkCloudVersion()
                }
            }
            .keyboardShortcut("o", modifiers: .command)
            Button("") {
                Task {
                    await gameManager.loadGameStateLocally()
                }
            }
            .keyboardShortcut("l", modifiers: [.command])
        }
        .frame(width: 0, height: 0)
        .hidden()
    }
}
