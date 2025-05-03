//
//  GameCheatsView.swift
//  Speed2048
//
//  Created by Lucas Longo on 5/3/25.
//

import SwiftUI

struct GameCheatsView: View {
    @EnvironmentObject var gameManager: GameManager
    
    let columns = [
        GridItem(.flexible(), alignment: .center),
        GridItem(.flexible(), alignment: .center),
        GridItem(.flexible(), alignment: .center),
    ]
    
    var body: some View {
        
        HStack(alignment: .center)  {
            
            Spacer()
            Text("Cheats")
                .bold()
                
            LazyVGrid(columns: columns, spacing: 10) {
                ScoreUnitView(text:"Undos", icon: "arrow.uturn.backward.circle", value: gameManager.undosUsed.formatted())
                ScoreUnitView(text:"+4s", icon: "4.circle", value: gameManager.manual4sUsed.formatted())
                ScoreUnitView(text:"Deletes", icon: "trash", value: gameManager.deletedTilesCount.formatted())
            }
            
            Spacer()
        }
        .foregroundStyle(gameManager.fontColor)
        
    }
}
