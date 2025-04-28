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
            ColorPicker(selection: $gameManager.backgroundColor.onChange { newColor in
                // Sync baseButtonColor with backgroundColor changes
                gameManager.baseButtonColor = newColor
            }) {
//                Label("", systemImage: "person.and.background.striped.horizontal")
                Text("BGR")
                    .foregroundStyle(gameManager.fontColor)
            }

            Spacer()
            Divider()
            Spacer()

            ColorPicker(selection: $gameManager.fontColor) {
//                Label("", systemImage: "character.circle.fill")
                Text("TXT")
                    .foregroundStyle(gameManager.fontColor)
            }

            Spacer()
            Divider()
            Spacer()

            ColorPicker(selection: $gameManager.baseButtonColor) {
//                Label("", systemImage: "button.programmable")
                Text("BTN")
                    .foregroundStyle(gameManager.fontColor)
            }
        }
    }
}

// Add an extension to support onChange for Binding
extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler(newValue)
            }
        )
    }
}

