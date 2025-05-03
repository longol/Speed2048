//
//  ColorPickerBackground.swift
//  Speed2048
//
//  Created by Lucas Longo on 5/3/25.
//

import SwiftUI

struct ColorPickerBackground: View {
    @EnvironmentObject var gameManager: GameManager

    var body: some View {
        HStack(alignment: .center)  {
     
            Spacer()

            ColorPicker(selection: $gameManager.baseButtonColor) {
                Label("Buttons", systemImage: "button.programmable")
                    .foregroundStyle(gameManager.fontColor)
            }
            
            Spacer()
        }
    }
}
