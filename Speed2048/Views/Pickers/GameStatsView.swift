//
//  GameStatsView.swift
//  Speed2048
//
//  Created by Lucas Longo on 5/3/25.
//

import SwiftUI

struct GameStatsView: View {
    @EnvironmentObject var gameManager: GameManager
    
    let columns = [
        GridItem(.flexible(), alignment: .center),
        GridItem(.flexible(), alignment: .center),
    ]

    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            Text("Stats")
                .bold()
            LazyVGrid(columns: columns) {
                ScoreUnitView(text: "Time", icon: "clock", value: gameManager.seconds.formattedAsTime)
                ScoreUnitView(text: "Sum", icon: "sum", value: gameManager.totalScore.formatted())
            }
            Spacer()
        }
        .foregroundStyle(gameManager.fontColor)
    }
}
