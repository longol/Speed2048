//
//  TileModelView.swift
//  TwentyFortyEight
//
//  Created by Lucas Longo on 2/17/25.
//

import SwiftUI

/// A tile on the board.
struct Tile: Identifiable, Equatable, Codable {
    let id: UUID
    var value: Int
    var row: Int
    var col: Int
}

/// A view for an individual tile.
struct TileView: View {
    var tile: Tile
    var cellSize: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cellSize * 0.1)
                .fill(tile.value.colorForValue)
            Text("\(tile.value)")
                .font(.system(size: cellSize * 0.4, weight: .bold))
                .foregroundColor(.white)
                .minimumScaleFactor(0.5) // Adjust the scale factor as needed
                .lineLimit(1) // Ensure the text is on a single line
        }
        .frame(width: cellSize - 4, height: cellSize - 4)
        // The tile’s position is computed from its row/column.
        .position(x: CGFloat(tile.col) * cellSize + cellSize/2,
                  y: CGFloat(tile.row) * cellSize + cellSize/2)
    }
    

}

