import SwiftUI
#if os(macOS)
import AppKit
#endif

// MARK: - Views

/// The main game view.
struct ContentView: View {
    @StateObject var gameModel: GameViewModel
//    @Environment(\.scenePhase) var scenePhase
    
    @State private var showAlert = false
    @State private var showSettings: Bool = false
    
    let boardDimension: CGFloat = 4
    let cellSize: CGFloat = 80
    
    var lastTwoTiles : [Int] {
        Array(gameModel.tileDurations.keys.sorted().suffix(2))
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            headerView
            
            controlButtonsView
            
            Spacer()
            
            gameBoardView
            
        }
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 500)
        #endif
        .dynamicTypeSize(.xSmall ... .xxxLarge)
        .sheet(isPresented: $showSettings) {
            SettingsView(gameModel: gameModel)
        }
    }
        
    @ViewBuilder private var headerView: some View {
        VStack(alignment: .center) {
            HStack {
                Text("131072 Quest")
                    .font(.largeTitle)
                    .bold()
                
                Spacer()
                
                settingsButton
            }
                        
            scoresView


        }
        .padding()
    }
   
    @ViewBuilder private var scoresView: some View {
        
        let columnsScores = [
            GridItem(.flexible(), alignment: .center),
            GridItem(.flexible(), alignment: .center),
            GridItem(.flexible(), alignment: .center),
            GridItem(.flexible(), alignment: .center)
        ]
        let columnsTimesToBeat = [
            GridItem(.flexible(), alignment: .center),
            GridItem(.flexible(), alignment: .center),
            GridItem(.flexible(), alignment: .center)
        ]
        
        VStack {

            LazyVGrid(columns: columnsScores, spacing: 10) {
                Image(systemName: "clock")
                Image(systemName: "sum")
                Image(systemName: "flag.pattern.checkered")
                Image(systemName: "circle.grid.cross.up.filled")

                Text("\(gameModel.seconds.formattedAsTime)")
                Text("\(gameModel.totalScore)")
                Text("\(gameModel.tiles.map { $0.value }.max() ?? 0)")
                Text("\(gameModel.cheatsUsed)")
            }

            LazyVGrid(columns: columnsTimesToBeat, spacing: 10) {
                // Table headers
                Label("Number", systemImage: "number")
                Label("Beat", systemImage: "trophy")
                Label("Current", systemImage: "figure.run")
                
                if lastTwoTiles.count >= 2 {
                    ForEach(lastTwoTiles.sorted(by: >), id: \.self) { tile in
                        gridRow(for: tile, useData: true)
                    }
                } else if lastTwoTiles.count == 1 {
                    // First row: static values for tile 16
                    gridRow(for: 16, useData: false)
                    // Second row: dynamic values for tile 8
                    gridRow(for: 8, useData: true)
                } else {
                    // Both rows: static values when no data is available
                    gridRow(for: 16, useData: false)
                    gridRow(for: 8, useData: false)
                }
            }
        }
        .padding()
        .font(.system(size: 18, weight: .medium))
        .minimumScaleFactor(0.5)  // allow text to shrink to 50% of its size
        .lineLimit(1)             // keep it on one line

    }
    
    @ViewBuilder private var controlButtonsView: some View {
        HStack(spacing: 10) {
            undoButton
            addFourButton
            newButton
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
            
        }
        .aspectRatio(1, contentMode: .fit)
        .padding()
        .layoutPriority(1)  // ensure the game board isn't squeezed by other views
    }

    func fgColor(tile: Int) -> Color {
        if let curr = gameModel.secondsSinceLast(for: tile), let avg = gameModel.averageTime(for: tile) {
            return Double(curr) > avg ? .red : .green
        }
        
        return .black
    }
    
    @ViewBuilder private func gridRow(for tile: Int, useData: Bool) -> some View {
        
        Group {
            Text("\(tile)").bold()

            Group {
                if useData {
                    Text(gameModel.averageTimeString(for: tile))
                    Text(gameModel.currentTimeString(for: tile))
                } else {
                    Text("-")
                    Text("-")
                }
            }
            .foregroundColor(fgColor(tile: tile))
        }

    }
    
    @ViewBuilder private var settingsButton: some View {
        Button {
            showSettings.toggle()
            gameModel.stopTimer()
        } label: {
            Image(systemName: "gear")
        }
    }
    
    @ViewBuilder private var newButton: some View {
        Button(action: { showAlert = true }) {
            Text("New")
        }
        .gameButtonStyle(gradient: LinearGradient(gradient: Gradient(colors: [Color.green, Color.teal]), startPoint: .topLeading, endPoint: .bottomTrailing))
        .keyboardShortcut("n", modifiers: [.command])
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
            Text("Undo")
        }
        .gameButtonStyle(gradient: LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]),
                                                  startPoint: .topLeading, endPoint: .bottomTrailing))
        .keyboardShortcut("z", modifiers: [.command])
    }
    
    @ViewBuilder private var addFourButton: some View {
        Button(action: { gameModel.forceTile() }) {
            Text("+4")
        }
        .gameButtonStyle(gradient: LinearGradient(gradient: Gradient(colors: [Color.red, Color.yellow]),
                                                  startPoint: .topLeading, endPoint: .bottomTrailing))
        .keyboardShortcut("4", modifiers: [.command])
    }

}

