//
//  TileColorPreviewView.swift
//  Speed2048
//
//  Created by Lucas Longo on 4/27/25.
//

import SwiftUI

struct TileColorPreviewView: View {
    @EnvironmentObject var gameManager: GameManager
    
    let sampleValues = [2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536, 131072]
    let tileSize: CGFloat = 40
    
    var body: some View {
        VStack(alignment: .leading) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(sampleValues, id: \.self) { value in
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(value.colorForValue(baseColor: gameManager.backgroundColor))
                            Text("\(value)")
                                .font(.system(size: tileSize * 0.4, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(width: tileSize + 25, height: tileSize)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}
