import SwiftUI

// MARK: - Views

/// The main game view.
struct ContentView: View {
    @StateObject var gameModel: GameViewModel
    
    @State private var showAlert = false
    @State private var showSettings: Bool = false
    
    let boardDimension: CGFloat = 4
    let cellSize: CGFloat = 80
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .center, spacing: 0) {
                headerView
                scoresView
                Spacer()
            }
            VStack(alignment: .center) {
                gameButtonsView
                Spacer()
                gameBoardView
                Spacer()
            }
        }
        .dynamicTypeSize(.xSmall ... .xxxLarge)
        .sheet(isPresented: $showSettings) {
            SettingsView(gameModel: gameModel)
        }
        .alert(isPresented: $gameModel.showVersionChoiceAlert) {
            Alert(
                title: Text("Cloud Game Found"),
                message: Text("Cloud game with higher score found. Use it or use your local version?"),
                primaryButton: .default(Text("Use Cloud")) {
                    gameModel.applyVersionChoice(useCloud: true)
                },
                secondaryButton: .destructive(Text("Use Local")) {
                    gameModel.applyVersionChoice(useCloud: false)
                }
            )
        }
        .onDisappear {
            gameModel.saveGameState()
        }
    }
        
    @ViewBuilder private var headerView: some View {
        HStack {
            Text("Quest for 131072")
                .font(.largeTitle)
                .bold()
            
            Spacer()
        
        }
        .padding()
    }
   
    @ViewBuilder private var scoresView: some View {
        
        let columns = [
            GridItem(.flexible(maximum: 55), alignment: .leading),
            GridItem(.flexible(), alignment: .leading),
            GridItem(.flexible(), alignment: .trailing),
        ]
        
        VStack {
        
            LazyVGrid(columns: columns, spacing: 30) {
                scoreUnit(text: "Level", icon: "quotelevel", value: gameModel.gameLevel.description)
                scoreUnit(text:"Goal", icon: "flag.pattern.checkered", value: (2 * (gameModel.tiles.map { $0.value }.max() ?? 0)).formatted())
                scoreUnit(text: "Time", icon: "clock", value: gameModel.seconds.formattedAsTime)
                scoreUnit(text: "Sum", icon: "sum", value: gameModel.totalScore.formatted())
                scoreUnit(text:"Undos", icon: "arrow.uturn.backward.circle", value: gameModel.undosUsed.formatted())
                scoreUnit(text:"+4s", icon: "die.face.4", value: gameModel.manual4sUsed.formatted())
            }
        }
        .minimumScaleFactor(0.5)  // allow text to shrink to 50% of its size
        .lineLimit(1)             // keep it on one line
        .padding()

    }
    
    @ViewBuilder private func scoreUnit(text: String, icon: String, value: String) -> some View {
        Group {
            Image(systemName: icon)
                .font(.system(size: 38, weight: .bold))
            Text("\(text):")
                .font(.system(size: 38, weight: .bold))
            Text(value)
                .font(.system(size: 38, weight: .regular))
        }

    }

    @ViewBuilder private var gameButtonsView: some View {
        HStack(spacing: 10) {
            settingsButton
            newButton
            Spacer()
            addFourButton
            undoButton
        }
        .padding()
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
            .background(KeyEventHandlingView { key in
                switch key {
                case .left:  gameModel.move(.left)
                case .right: gameModel.move(.right)
                case .up:    gameModel.move(.up)
                case .down:  gameModel.move(.down)
                }
            })
            .focusable(true) // Enable focus for tvOS
            .onMoveCommand { direction in
                switch direction {
                case .left:
                    gameModel.move(.left)
                case .right:
                    gameModel.move(.right)
                case .up:
                    gameModel.move(.up)
                case .down:
                    gameModel.move(.down)
                default:
                    break
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .padding()
        .layoutPriority(1)  // ensure the game board isn't squeezed by other views
    }

    @ViewBuilder private var settingsButton: some View {
        Button {
            showSettings.toggle()
            gameModel.stopTimer()
        } label: {
            Image(systemName: "gear")
        }
        .gameButtonStyle(
            gradient: LinearGradient(
                gradient: Gradient(
                    colors: [64.colorForValue, 32768.colorForValue]
                ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            maxHeight: 80,
            minWidth: 80
        )
    }
    
    @ViewBuilder private var newButton: some View {
        Button(action: { showAlert = true }) {
            Image(systemName: "plus.circle")
        }
        .gameButtonStyle(
            gradient: LinearGradient(
                gradient: Gradient(
                    colors: [64.colorForValue, 8192.colorForValue]
                ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            maxHeight: 80,
            minWidth: 80
        )
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Start New Game"),
                message: Text("Are you sure you want to start a new game?"),
                primaryButton: .destructive(Text("Start")) {
                    gameModel.newGame()
                },
                secondaryButton: .cancel()
            )
        }
    }
     
    @ViewBuilder private var undoButton: some View {
        Button(action: { gameModel.undo() }) {
            Image(systemName: "arrow.uturn.backward.circle")
        }
        .gameButtonStyle(
            gradient: LinearGradient(
                gradient: Gradient(
                    colors: [64.colorForValue, 256.colorForValue]
                ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            maxHeight: 80,
            minWidth: 80
        )
    }
    
    @ViewBuilder private var addFourButton: some View {
        Button(action: { gameModel.forceTile() }) {
            Image(systemName: "4.circle")
        }
        .gameButtonStyle(
            gradient: LinearGradient(
                gradient: Gradient(
                    colors: [64.colorForValue, 2048.colorForValue]
                ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            maxHeight: 80,
            minWidth: 80
        )
    }

}

