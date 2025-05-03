//
//  ScoreUnitView.swift
//  Speed2048
//
//  Created by Lucas Longo on 5/3/25.
//

import SwiftUI

struct ScoreUnitView: View {
    @EnvironmentObject var gameManager: GameManager
    
    var text: String
    var icon: String
    var value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                
            Text(value)
                .font(.system(size: 18, weight: .regular))
        }
        .minimumScaleFactor(0.5)
        .lineLimit(1)
        .foregroundStyle(gameManager.fontColor)
    }
}
