//
//  OverlayMessageView.swift
//  Speed2048
//
//  Created by Lucas Longo on 5/3/25.
//

import SwiftUI

struct OverlayMessageView: View {
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        VStack(alignment: .center) {
            if gameManager.showOverlayMessage {
                Text(gameManager.overlayMessage)
                    .foregroundStyle(.black)
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
        .frame(height: 50)
        .padding(.vertical, 10)

    }
}
