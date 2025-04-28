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
    var isEditMode: Bool
    var themeColor: Color = .blue.opacity(0.2)  // Default theme color
    var onDelete: ((UUID) -> Void)?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cellSize * 0.1)
                .fill(tile.value.colorForValue(baseColor: themeColor))

            Text("\(tile.value)")
#if os(watchOS)
                .font(.system(size: cellSize * 0.5, weight: .bold))
#else
                .font(.system(size: cellSize * 0.25, weight: .bold))
#endif
                .foregroundStyle(.white)
                .minimumScaleFactor(0.05) // Adjust the scale factor as needed
                .lineLimit(1) // Ensure the text is on a single line
                .overlay(
                    isEditMode ?
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: cellSize * 0.3))
                        .foregroundStyle(.white)
                        .opacity(0.8)
                        .offset(x: cellSize * 0.25, y: -cellSize * 0.25)
                    : nil
                )
                .onTapGesture {
//                    if isEditMode, let onDelete = onDelete {
//                        onDelete(tile.id)
//                    }
                }
        }
        .frame(width: cellSize - 4, height: cellSize - 4)
        .position(x: CGFloat(tile.col) * cellSize + cellSize/2,
                  y: CGFloat(tile.row) * cellSize + cellSize/2)
        
    }
}

