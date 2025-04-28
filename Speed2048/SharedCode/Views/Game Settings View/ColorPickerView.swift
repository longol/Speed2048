//
//  ColorPickerView.swift
//  Speed2048
//
//  Created by Lucas Longo on 4/25/25.
//

import SwiftUI

struct ColorPickerView: View {
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        HStack {
            ColorPicker(selection: $gameManager.backgroundColor) {
                Label("Background", systemImage: "person.and.background.striped.horizontal")
                    .foregroundStyle(gameManager.fontColor)
            }

            Spacer()
            Divider()
            Spacer()

            ColorPicker(selection: $gameManager.fontColor) {
                Label("Text", systemImage: "character.circle.fill")
                    .foregroundStyle(gameManager.fontColor)
            }
        }
    }
}
