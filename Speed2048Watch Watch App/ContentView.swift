import SwiftUI
/// The main game view.
struct ContentView: View {
    @StateObject var gameModel: GameViewModel

    @State private var showScoreView = false // State to control ScoreView presentation

    let boardDimension: CGFloat = 4
    let cellSize: CGFloat = 80
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            gameBoardView
        }
        .dynamicTypeSize(.xSmall ... .xxxLarge)
        .onDisappear {
            gameModel.saveGameState()
        }
        .sheet(isPresented: $showScoreView) {
            ScoreView(gameModel: gameModel) // Present the ScoreView
        }
    }
        
    @ViewBuilder private var gameBoardView: some View {
        GeometryReader { geo in
            let side = geo.size.width
            let cellSize = side / boardDimension
            ZStack {
                // Draw the background grid.
                ForEach(0..<Int(boardDimension), id: \.self) { row in
                    ForEach(0..<Int(boardDimension), id: \.self) { col in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: cellSize-2, height: cellSize-2)
                            .position(
                                x: CGFloat(col) * cellSize + cellSize/2,
                                y: CGFloat(row) * cellSize + cellSize/2
                            )
                    }
                }
                // Draw the tiles.
                ForEach(gameModel.tiles) { tile in
                    TileView(tile: tile, cellSize: cellSize)
                }
            }
            .frame(width: side, height: side)
            .background(Color.gray.opacity(0.3))
            .cornerRadius(8)
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        let horizontal = value.translation.width
                        let vertical = value.translation.height
                        let direction: Direction = (abs(horizontal) > abs(vertical)) ?
                        (horizontal > 0 ? .right : .left) :
                        (vertical > 0 ? .down : .up)
                        gameModel.move(direction)
                    }
            )
            .gesture(
                TapGesture()
                    .onEnded {
                        showScoreView = true // Open the ScoreView when tapped
                    }
            )

            
        }
        .aspectRatio(1, contentMode: .fit)
        .layoutPriority(1)  // ensure the game board isn't squeezed by other views
    }
}

