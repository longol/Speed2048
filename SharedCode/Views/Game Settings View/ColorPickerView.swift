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
        VStack(alignment: .leading) {
            ColorPicker("Background color", selection: $gameManager.backgroundColor)
                .padding(.vertical, 5)
                .bold()
        }
    }
}
