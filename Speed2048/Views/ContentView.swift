import SwiftUI
#if os(macOS)
import AppKit
#endif

// MARK: - Views

/// The main game view.
struct ContentView: View {
    @ObservedObject var gameManager: GameManager
    
    @State private var showAlert = false
    @State private var showSettings: Bool = false
    
    @State private var undoTimer: Timer?
    
    // Remove the hardcoded boardDimension constant and use a computed property instead
    var boardDimension: CGFloat {
        CGFloat(gameManager.boardSize)
    }
    let cellSize: CGFloat = 80
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            headerView
            
#if os(macOS)
            scoresViewMac
#else
            scoresView
#endif
            
            statusMessage
            Spacer()
            gameButtonsView
            gameBoardView
            
            keyboardShortcuts
        }
#if os(macOS)
        .frame(minWidth: 400, minHeight: 500)
#endif
        .dynamicTypeSize(.xSmall ... .xxxLarge)
        .sheet(isPresented: $showSettings) {
            SettingsView(gameManager: gameManager)
        }
        .onDisappear {
            Task {
                await gameManager.saveGameState()
            }
        }
    }
    
    @ViewBuilder private var keyboardShortcuts: some View {
        Group {
            Button("") {
                Task {
                    await gameManager.saveGameState()
                }
            }
            .keyboardShortcut("s", modifiers: .command)
            
            Button("") {
                Task {
                    await gameManager.checkCloudVersion()
                }
            }
            .keyboardShortcut("o", modifiers: .command)
            Button("") {
                Task {
                    await gameManager.loadGameStateLocally()
                }
            }
            .keyboardShortcut("l", modifiers: [.command])
        }
        .frame(width: 0, height: 0)
        .hidden()
    }
    
    @ViewBuilder private var headerView: some View {
        HStack {
            Text("Speed 2048")
                .font(.largeTitle)
                .bold()
            
            Spacer()
            
            settingsButton
        }
        .padding()
        .alert(isPresented: $gameManager.showVersionChoiceAlert) {
            Alert(
                title: Text("Cloud Game Found"),
                message: Text("Cloud game with higher score found. Use it or use your local version?"),
                primaryButton: .default(Text("Use Cloud")) {
                    gameManager.applyVersionChoice(useCloud: true)
                },
                secondaryButton: .destructive(Text("Use Local")) {
                    gameManager.applyVersionChoice(useCloud: false)
                }
            )
        }
    }
    
    @ViewBuilder private var scoresViewMac: some View {
        HStack(alignment: .top) {
            scoresView
            Spacer()
            VStack(alignment: .leading) {
                EscalatingModeToggle(gameManager: gameManager, showTitle: false)
                AnimationSpeedToggle(gameManager: gameManager, showTitle: false)
            }
            VStack(alignment: .leading) {
                GameLevelPicker(gameManager: gameManager, showTitle: false)
                BoardSizePicker(gameManager: gameManager, showTitle: false)
            }
        }
    }
    
    @ViewBuilder private var scoresView: some View {
        
        let columnsTwo = [
            GridItem(.flexible(), alignment: .leading),
            GridItem(.flexible(), alignment: .leading),
        ]
        
        let columnsOne = [
            GridItem(.flexible(), alignment: .leading),
            GridItem(.flexible(), alignment: .leading),
        ]

        VStack {
            
            LazyVGrid(columns: columnsTwo, spacing: 10) {
                scoreUnit(text: "Level", icon: "quotelevel", value: gameManager.gameLevel.description)
                scoreUnit(text: "Sum", icon: "sum", value: gameManager.totalScore.formatted())
            }
            
            LazyVGrid(columns: columnsTwo, spacing: 10) {
                
                scoreUnit(text:"Undos", icon: "arrow.uturn.backward.circle", value: gameManager.undosUsed.formatted())
                scoreUnit(text:"+4s", icon: "4.circle", value: gameManager.manual4sUsed.formatted())
            }
            
            LazyVGrid(columns: columnsOne, spacing: 10) {
                Label("Time:", systemImage: "clock")
                    .font(.system(size: 18, weight: .bold))
                Text(gameManager.seconds.formattedAsTime)
                    .font(.system(size: 18, weight: .regular))
            }
        }
        .padding()
        
    }
    
    @ViewBuilder private func scoreUnit(text: String, icon: String, value: String) -> some View {
        HStack {
            Label("\(text):", systemImage: icon)
                .font(.system(size: 18, weight: .bold))
            Text(value)
                .font(.system(size: 18, weight: .regular))
        }
        .minimumScaleFactor(0.5)  // allow text to shrink to 50% of its size
        .lineLimit(1)             // keep it on one line
        
    }
    
    @ViewBuilder private var statusMessage: some View {
        HStack {
            if !gameManager.statusMessage.isEmpty {
                Label(gameManager.statusMessage, systemImage: "bolt.horizontal.icloud")
                ProgressView()
                    .scaleEffect(0.5)
            } else {
                EmptyView()
            }
        }
        .font(.callout)
        .frame(height: 30)
        .foregroundStyle(.gray.opacity(0.5))
        .layoutPriority(1)  // ensure the game board isn't squeezed by other views
    }

    @ViewBuilder private var gameButtonsView: some View {
        VStack(alignment: .center) {
            HStack {
                undoButton
                    .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 0))
                addFourButton
                Spacer()
                newButton
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 20))
            }
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
                ForEach(gameManager.tiles) { tile in
                    TileView(tile: tile, cellSize: cellSize)
                }
                
                // Game message overlay
                if gameManager.showOverlayMessage {
                    Text(gameManager.overlayMessage)
                        .font(.system(size: min(50, side/5), weight: .bold))
                        .foregroundStyle(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.5))
                                .shadow(radius: 5)
                        )
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(100) // Ensure it's above all other elements
                }
            }
            .frame(width: side, height: side)
            .background(Color.gray.opacity(0.3))
            .cornerRadius(8)
            .background(KeyEventHandlingView { key in
                switch key {
                case .left:  gameManager.move(.left)
                case .right: gameManager.move(.right)
                case .up:    gameManager.move(.up)
                case .down:  gameManager.move(.down)
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
                        gameManager.move(direction)
                    }
            )
            .animation(.easeInOut(duration: 0.3), value: gameManager.showOverlayMessage)
        }
        .aspectRatio(1, contentMode: .fit)
        .padding()
        .layoutPriority(1)  // ensure the game board isn't squeezed by other views
    }
    
    @ViewBuilder private var settingsButton: some View {
        Button {
            showSettings.toggle()
            gameManager.stopTimer()
        } label: {
            Image(systemName: "gear")
        }
        .keyboardShortcut(",", modifiers: [.command])
        .gameButtonStyle(
            gradient: LinearGradient(
                gradient: Gradient(
                    colors: [64.colorForValue, 32768.colorForValue]
                ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            maxHeight: 55,
            minWidth: 55
        )
    }
    
    @ViewBuilder private var newButton: some View {
        Button(action: {
            showAlert = true
            gameManager.stopTimer()
        }) {
            Image(systemName: "plus.circle")
        }
        .keyboardShortcut("n", modifiers: [.command])
        .gameButtonStyle(
            gradient: LinearGradient(
                gradient: Gradient(
                    colors: [64.colorForValue, 8192.colorForValue]
                ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            maxHeight: 55,
            minWidth: 55
        )
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Start New Game"),
                message: Text("Are you sure you want to start a new game?"),
                primaryButton: .default(
                    Text("Cancel"),
                    action: gameManager.startTimer
                ),
                secondaryButton: .destructive(
                    Text("New Game"),
                    action: gameManager.newGame
                )
            )
        }
        .onChange(of: showAlert, { oldValue, newValue in
            if !newValue {
                gameManager.startTimer() // Restart the timer when the alert is dismissed
            }
        })
    }
    
    @ViewBuilder private var undoButton: some View {
        Button(action: { gameManager.undo() }) {
            Image(systemName: "arrow.uturn.backward.circle")
        }
        .onLongPressGesture(
            minimumDuration: 0.1, // Adjust the duration for responsiveness
            pressing: { isPressing in
                if isPressing {
                    startUndoTimer()
                } else {
                    stopUndoTimer()
                }
            },
            perform: {}
        )
        .gameButtonStyle(
            gradient: LinearGradient(
                gradient: Gradient(
                    colors: [64.colorForValue, 256.colorForValue]
                ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            maxHeight: 55,
            minWidth: 100
        )
        .keyboardShortcut("z", modifiers: [.command])
        
    }
    
    @ViewBuilder private var addFourButton: some View {
        Button(action: { gameManager.forceTile() }) {
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
            maxHeight: 55,
            minWidth: 100
        )
        .keyboardShortcut("4", modifiers: [.command])
    }
    

    private func startUndoTimer() {
        stopUndoTimer() // Ensure no existing timer is running
        undoTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            Task { @MainActor in
                gameManager.undo()
            }
        }
    }
    
    private func stopUndoTimer() {
        undoTimer?.invalidate()
        undoTimer = nil
    }
}

