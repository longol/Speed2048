//
//  TileModelView.swift
//  TwentyFortyEight
//
//  Created by Lucas Longo on 2/17/25.
//

import SwiftUI

struct TileView: View {
    var tile: Tile
    var cellSize: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cellSize * 0.1)
                .fill(tile.value.colorForValue)
            Text("\(tile.value)")
            #if os(watchOS)
                .font(.system(size: cellSize * 0.5, weight: .bold))
            #else
                .font(.system(size: cellSize * 0.25, weight: .bold))
            #endif
                .foregroundColor(.white)
                .minimumScaleFactor(0.05) // Adjust the scale factor as needed
                .lineLimit(1) // Ensure the text is on a single line
        }
        .frame(width: cellSize - 4, height: cellSize - 4)
        // The tile’s position is computed from its row/column.
        .position(x: CGFloat(tile.col) * cellSize + cellSize/2,
                  y: CGFloat(tile.row) * cellSize + cellSize/2)
    }
    

}

