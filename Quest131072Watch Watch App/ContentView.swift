//
//  ContentView.swift
//  Quest131072Watch Watch App
//
//  Created by Lucas Longo on 4/5/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var gameModel: GameViewModel

    var body: some View {
        GeometryReader { geo in
            let cellSize = geo.size.width / 4
            ZStack {
                ForEach(0..<4, id: \.self) { row in
                    ForEach(0..<4, id: \.self) { col in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: cellSize - 2, height: cellSize - 2)
                            .position(
                                x: CGFloat(col) * cellSize + cellSize / 2,
                                y: CGFloat(row) * cellSize + cellSize / 2
                            )
                    }
                }
                ForEach(gameModel.tiles) { tile in
                    TileView(tile: tile, cellSize: cellSize)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    let horizontal = value.translation.width
                    let vertical = value.translation.height
                    let direction: Direction = (abs(horizontal) > abs(vertical)) ?
                    (horizontal > 0 ? .right : .left) :
                    (vertical > 0 ? .down : .up)
                    gameModel.move(direction)
                }
        )
    }
}

