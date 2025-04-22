//
//  GameLevelPicker.swift
//  Speed2048
//
//  Created by Lucas Longo on 4/22/25.
//

import SwiftUI

struct GameLevelPicker: View {
    @ObservedObject var gameManager: GameManager
    var showTitle = true

    var body: some View {
        VStack(alignment: .leading) {
            
            if showTitle {
                Text("Game Level").bold()
            }
            Picker("Game Level", selection: $gameManager.gameLevel) {
                ForEach(GameLevel.allCases, id: \.self) { level in
                    Text(level.description).tag(level)
                }
            }
#if os(watchOS)
            .pickerStyle(InlinePickerStyle())
#else
            .pickerStyle(SegmentedPickerStyle())
#endif
            
            if showTitle {
                HStack {
                    Spacer()
                    Text(gameManager.gameLevel.penaltyString)
                        .font(.caption)
                    Spacer()
                }
            }
        }
    }
}
