//
//  ColorPickerButtons.swift
//  Speed2048
//
//  Created by Lucas Longo on 5/3/25.
//

import SwiftUI

struct ColorPickerButtons: View {
    @EnvironmentObject var gameManager: GameManager

    var body: some View {
        HStack(alignment: .center)  {
            
            Spacer()
            
            ColorPicker(selection: $gameManager.fontColor) {
                Label("Fonts", systemImage: "character.circle.fill")
                    .foregroundStyle(gameManager.fontColor)
            }
            
            Spacer()
        }
    }
}
