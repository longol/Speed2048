//
//  ColorPickerFonts.swift
//  Speed2048
//
//  Created by Lucas Longo on 5/3/25.
//

import SwiftUI

struct ColorPickerFonts: View {
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        HStack(alignment: .center)  {
            
            Spacer()
            
            ColorPicker(selection: $gameManager.fontColor) {
                Label("Font Colors", systemImage: "button.programmable")
                    .bold()
            }
            
            Spacer()
            
        }
        .foregroundStyle(gameManager.fontColor)
        
    }
}
