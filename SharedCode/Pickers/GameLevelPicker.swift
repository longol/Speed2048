//
//  GameLevelPicker.swift
//  Speed2048
//
//  Created by Lucas Longo on 4/22/25.
//

import SwiftUI

struct GameLevelPicker: View {
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        HStack(alignment: .center) {
            
            Spacer()
            
            Picker(selection: $gameManager.gameLevel) {
                ForEach(GameLevel.allCases, id: \.self) { level in
                    Text(level.description).tag(level)
                }
            } label: {
                Label("Level", systemImage: "gearshift.layout.sixspeed")
                    .bold()
            }
#if os(watchOS)
            .pickerStyle(InlinePickerStyle())
#else
            .pickerStyle(PalettePickerStyle())
#endif
            Spacer()
        }
    }
}
