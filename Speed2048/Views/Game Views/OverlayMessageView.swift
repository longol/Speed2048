//
//  OverlayMessageView.swift
//  Speed2048
//
//  Created by Lucas Longo on 5/3/25.
//

import SwiftUI

struct OverlayMessageView: View {
    @EnvironmentObject var gameManager: GameManager
    
    let frameHeight: CGFloat = 60
    
    var body: some View {
        VStack(alignment: .center) {
            if gameManager.showOverlayMessage {
                Text(gameManager.overlayMessage)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .minimumScaleFactor(0.8)
                    .lineLimit(3)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(gameManager.baseButtonColor)
                            .shadow(radius: 5)
                    )
                    .transition(.scale.combined(with: .opacity))

            } else {
                EmptyView()
            }
        }
        .frame(height: frameHeight)
        .padding()
        .foregroundStyle(gameManager.fontColor)

    }
}
