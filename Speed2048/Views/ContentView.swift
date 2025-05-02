import SwiftUI
#if os(macOS)
import AppKit
#endif

// MARK: - Views

/// The main game view.
struct ContentView: View {
    @EnvironmentObject var gameManager: GameManager
    
    @State private var showAlert = false
    @State private var showSettings: Bool = false
    
    @State private var undoTimer: Timer?
    
    @State private var selectedTab: Int = 0
    
    var boardDimension: CGFloat {
        CGFloat(gameManager.boardSize)
    }
    let cellSize: CGFloat = 80
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            headerView
            Divider()
            scoresAndPickersTabView
            Spacer()
            overlayMessageView
            Spacer()
            gameButtonsView
            Spacer()
            gameBoardView
            keyboardShortcuts
        }
#if os(macOS)
        .frame(minWidth: 400, minHeight: 750)
#endif
        .dynamicTypeSize(.xSmall ... .xxxLarge)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onDisappear {
            Task {
                await gameManager.saveGameState()
            }
        }
        .background(gameManager.backgroundColor)
        .foregroundStyle(gameManager.fontColor)
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
    
    @ViewBuilder private var scoresAndPickersTabView: some View {
        VStack(spacing: 10) {
            HStack(spacing: 0) {

                leftIndexButton
                
                // Custom tab content with horizontal slide animation
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        Group {
                            gameLevelsView
                            visualSettingsView
                            scoresView
                        }
                        .frame(width: geo.size.width)
                    }
                    .offset(x: -CGFloat(selectedTab) * geo.size.width)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedTab)
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                let horizontalAmount = value.translation.width
                                let pageWidth = geo.size.width / 2
                                
                                // Determine swipe direction and update tab if needed
                                if horizontalAmount > pageWidth && selectedTab > 0 {
                                    selectedTab -= 1
                                } else if horizontalAmount < -pageWidth && selectedTab < 2 {
                                    selectedTab += 1
                                }
                            }
                    )
                }
                .clipped() // Prevents content from visibly overflowing
                
                rightIndexButton
            }
            .frame(height: 90)
            
            // Page indicators now in their own row
            pageIndicatorsView
                .padding(.bottom, 8)
                .opacity(0.5)
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder private var leftIndexButton: some View {
        Button(action: {
            selectedTab = selectedTab > 0 ? selectedTab - 1 : 2
        }) {
            Image(systemName: "chevron.left")
                .imageScale(.large)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var rightIndexButton: some View {
        Button(action: {
            selectedTab = selectedTab < 2 ? selectedTab + 1 : 0
        }) {
            Image(systemName: "chevron.right")
                .imageScale(.large)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var pageIndicatorsView: some View {
        HStack(spacing: 10) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(selectedTab == index ? Color.red : Color.gray)
                    .frame(width: 8, height: 8)
                    .onTapGesture {
                        selectedTab = index
                    }
            }
        }
    }
    
    @ViewBuilder private var scoresView: some View {
        
        let columns3 = [
            GridItem(.flexible(), alignment: .center),
            GridItem(.flexible(), alignment: .center),
            GridItem(.flexible(), alignment: .center),
        ]
        let columns2 = [
            GridItem(.flexible(), alignment: .center),
            GridItem(.flexible(), alignment: .center),
        ]
        
        VStack(alignment: .center) {
            LazyVGrid(columns: columns2, spacing: 10) {
                scoreUnit(text: "Time", icon: "clock", value: gameManager.seconds.formattedAsTime)
                scoreUnit(text: "Sum", icon: "sum", value: gameManager.totalScore.formatted())
            }

            Divider()
            
            LazyVGrid(columns: columns3, spacing: 10) {
                scoreUnit(text:"Undos", icon: "arrow.uturn.backward.circle", value: gameManager.undosUsed.formatted())
                scoreUnit(text:"+4s", icon: "4.circle", value: gameManager.manual4sUsed.formatted())
                scoreUnit(text:"Deletes", icon: "trash", value: gameManager.deletedTilesCount.formatted())
            }
            
        }
        .padding()
    }

    @ViewBuilder private var gameLevelsView: some View {
        VStack {
            GameLevelPicker()
            BoardSizePicker()
        }
        .padding()
    }

    @ViewBuilder private var visualSettingsView: some View {
        VStack {
            AnimationSpeedToggle()
            ColorPickerView()
        }
        .padding()
    }
    
    @ViewBuilder private func scoreUnit(text: String, icon: String, value: String) -> some View {
        HStack {
//            Label("\(text):", systemImage: icon)
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
            Text(value)
                .font(.system(size: 18, weight: .regular))
        }
        .minimumScaleFactor(0.5)  // allow text to shrink to 50% of its size
        .lineLimit(1)             // keep it on one line
        
    }
    
    @ViewBuilder private var gameButtonsView: some View {
        VStack(alignment: .center) {
            HStack {
                undoButton
                    .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 0))
                addFourButton
                Spacer()
                editButton
                newButton
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 20))
            }
        }
    }

    @ViewBuilder private var overlayMessageView: some View {
            VStack(alignment: .center) {
                if gameManager.showOverlayMessage {
                    Text(gameManager.overlayMessage)
                        .foregroundStyle(.black)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.5))
                                .shadow(radius: 5)
                        )
                        .transition(.scale.combined(with: .opacity))
                } else {
                    EmptyView()
                }
            }
            .frame(height: 50)
            .padding(.vertical, 10)
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
                    TileView(
                        tile: tile,
                        cellSize: cellSize,
                        isEditMode: gameManager.isEditMode,
                        themeColor: gameManager.baseButtonColor, // Change this from backgroundColor to baseButtonColor
                        onDelete: { id in
                            gameManager.deleteTile(id: id)
                        }
                    )
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
    }
    
    @ViewBuilder private var newButton: some View {
        Button(action: {
            showAlert = true
            gameManager.stopTimer()
        }) {
            Image(systemName: "plus.circle")
        }
        .keyboardShortcut("n", modifiers: [.command])
        .themeAwareButtonStyle(
            themeBackground: gameManager.backgroundColor,
            themeFontColor: gameManager.fontColor,
            uiSize: gameManager.uiSize
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
        .themeAwareButtonStyle(
            themeBackground: gameManager.backgroundColor,
            themeFontColor: gameManager.fontColor,
            uiSize: gameManager.uiSize
        )
        .keyboardShortcut("z", modifiers: [.command])
        
    }
    
    @ViewBuilder private var addFourButton: some View {
        Button(action: { gameManager.forceTile() }) {
            Image(systemName: gameManager.gameLevel == .onlyTwos ? "2.circle" :  "4.circle")
        }
        .themeAwareButtonStyle(
            themeBackground: gameManager.backgroundColor,
            themeFontColor: gameManager.fontColor,
            uiSize: gameManager.uiSize
        )
        .keyboardShortcut("4", modifiers: [.command])
        .keyboardShortcut("2", modifiers: [.command])
    }
    
    @ViewBuilder private var editButton: some View {
            Button(action: { gameManager.toggleEditMode() }) {
                Image(systemName: gameManager.isEditMode ? "pencil.slash" : "pencil")
            }
            .themeAwareButtonStyle(
                themeBackground: gameManager.isEditMode ? Color.red.opacity(0.7) : gameManager.backgroundColor,
                themeFontColor: gameManager.fontColor,
                uiSize: gameManager.uiSize
            )
            .keyboardShortcut("e", modifiers: [.command])
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
    
    private func startUndoTimer() {
        stopUndoTimer() // Ensure no existing timer is running
        undoTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
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

