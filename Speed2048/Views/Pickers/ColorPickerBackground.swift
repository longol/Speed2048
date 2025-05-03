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

            ColorPicker(selection: $gameManager.backgroundColor) {
                Label("Background Colors", systemImage: "person.and.background.striped.horizontal")
                    .bold()
            }
            
            Spacer()
        }
        .foregroundStyle(gameManager.fontColor)
        
    }
}
