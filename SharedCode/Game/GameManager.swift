//
//  GameManager.swift
//  Speed2048
//
//  Created by Lucas Longo on 4/14/25.
//

import SwiftUI

@MainActor
class GameManager: ObservableObject {
    // Services
    private let dataManager = DataManager()
    private var boardLogic: BoardLogic = BoardLogic()
    
    // Game state
    @Published var seconds: Int = 0
    @Published var gameLevel: GameLevel = .regular
    @Published var fastAnimations: Bool = false
    @Published var tiles: [Tile] = []
    @Published var undoStack: [[Tile]] = []
    @Published var undosUsed: Int = 0
    @Published var manual4sUsed: Int = 0
    @Published var isEditMode: Bool = false
    @Published var deletedTilesCount: Int = 0
    @Published var backgroundColor: Color = Color.blue.opacity(0.2)
    @Published var boardSize: Int = 4 {
        didSet {
            if oldValue != boardSize {
                boardLogic = BoardLogic(boardSize: boardSize)
            }
        }
    }
    @Published var previousHighMerge: Int = 128
    var highestTileValue: Int {
        return tiles.map { $0.value }.max() ?? 2
    }
    
    // UI state
    @Published var statusMessage: String = ""
    @Published var showVersionChoiceAlert: Bool = false
    @Published var loadingGame: Bool = true

    // Overlay message state
    @Published var overlayMessage: String = ""
    @Published var showOverlayMessage: Bool = false
    private var overlayMessageTask: Task<Void, Never>? = nil
    
    // Private state
    private var fetchedCloudGameState: GameState? = nil
    private var timer: Timer? = nil
    
    private var animationState: GameAnimationState = .idle
    
    var gameState: GameState {
        let (r, g, b, a) = backgroundColor.components

        return GameState(
            tiles: tiles,
            seconds: seconds,
            undoStack: undoStack,
            gameLevel: gameLevel,
            fastAnimations: fastAnimations,
            undosUsed: undosUsed,
            manual4sUsed: manual4sUsed,
            boardSize: boardSize,
            deletedTilesCount: deletedTilesCount,
            backgroundColorRed: r,
            backgroundColorGreen: g,
            backgroundColorBlue: b,
            backgroundColorOpacity: a
        )
    }
    
    init() {
        Task {
            loadingGame = true
            
            // First try to load the local game
            let loadedSuccessfully = await loadGameStateLocally()
            
            // Only check cloud if we successfully loaded a local game
            if loadedSuccessfully {
                await checkCloudVersion()
                loadingGame = false
            } else {
                loadingGame = false
//                newGame()
//                showGameMessage("Started new game")
            }
        }
    }
    
    // MARK: - Game Data Management
    func checkCloudVersion() async {
        showGameMessage("Checking cloud")
        do {
            let cloudState = try await dataManager.fetchGameStateFromCloud()
            let cloudTotalScore = cloudState.tiles.reduce(0) { $0 + $1.value }
            
            if cloudTotalScore > totalScore {
                fetchedCloudGameState = cloudState
                self.showVersionChoiceAlert = true
                showGameMessage("Found higher scored game")
            } else {
                showGameMessage("Local game is current")
            }
        } catch {
            showGameMessage(error.localizedDescription)
        }
    }
    
    func loadGameStateLocally() async -> Bool {
        showGameMessage("Loading local game")
        do {
            let gameState = try await dataManager.loadGameStateLocally()
            applyGameState(gameState)
            showGameMessage("Loaded local game")
            return true
        } catch {
            showGameMessage("Failed to load: \(error.localizedDescription)")
            return false
        }
    }
    
    func saveGameState() async {
        stopTimer()
        showGameMessage("Saving game")
        do {
            try await dataManager.saveGameStateLocally(gameState: gameState)
            showGameMessage("Saved locally, now saving to cloud")
            try await dataManager.saveGameStateToCloud(gameState: gameState)
            showGameMessage("Saved to cloud")
        } catch {
            showGameMessage(error.localizedDescription)
        }
    }
    
    func applyVersionChoice(useCloud: Bool) {
        if useCloud, let cloudGameState = fetchedCloudGameState {
            showGameMessage("Applying cloud version")
            applyGameState(cloudGameState)
        } else if !useCloud {
            showGameMessage("Keeping local version")
        } else {
            showGameMessage("Game up to date")
        }
        // Reset temporary variables.
        showVersionChoiceAlert = false
        fetchedCloudGameState = nil
    }
    
    func applyGameState(_ gameState: GameState) {
        tiles = gameState.tiles
        seconds = gameState.seconds
        undoStack = gameState.undoStack
        gameLevel = gameState.gameLevel
        fastAnimations = gameState.fastAnimations
        undosUsed = gameState.undosUsed
        manual4sUsed = gameState.manual4sUsed
        boardSize = gameState.boardSize
        deletedTilesCount = gameState.deletedTilesCount
        backgroundColor = Color(
            red: gameState.backgroundColorRed,
            green: gameState.backgroundColorGreen,
            blue: gameState.backgroundColorBlue,
            opacity: gameState.backgroundColorOpacity
        )

        if !tiles.isEmpty {
            startTimer()
        }
    }
    
    // MARK: - Game Score
    var totalScore: Int {
        return tiles.reduce(0) { $0 + $1.value }
    }
    
    var cheatsUsed: Int {
        return undosUsed + manual4sUsed
    }
    
    
    // MARK: - Timer Management
    func startTimer() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                if !self.tiles.isEmpty {
                    self.seconds += 1
                }
            }
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Animation Properties
    var animationDurationSlide: Double {
        return AnimationHelper.slideDuration(fastMode: fastAnimations)
    }
    
    var animationDurationShowHide: Double {
        return AnimationHelper.showHideDuration(fastMode: fastAnimations)
    }
    
    // MARK: - Game Mechanics
    func newGame() {
        if loadingGame { return }

        stopTimer()
        tiles = []
        undoStack = []
        seconds = 0
        undosUsed = 0
        manual4sUsed = 0
        addRandomTile()
        addRandomTile()
        startTimer()
        showGameMessage("New Game Started")
    }
    
    func addRandomTile() {
        let emptyPositions = boardLogic.getEmptyPositions(tiles: tiles)
        guard !emptyPositions.isEmpty, let pos = emptyPositions.randomElement() else { return }
        
        // Determine the value based on the probability of fours
        let value = Double.random(in: 0..<1) < gameLevel.probabilityOfFours ? 4 : 2
        let tile = Tile(id: UUID(), value: value, row: pos.row, col: pos.col)
        
        withAnimation(.easeInOut(duration: self.animationDurationShowHide)) {
            tiles.append(tile)
        }
    }
    
    func move(_ direction: Direction) {
        if animationState != .idle { return }
        
        // Save current state for undo
        if undoStack.count > 20 {
            undoStack.removeFirst()
        }
        undoStack.append(tiles.map { $0 })
        
        let moveResult = boardLogic.calculateMoves(tiles: tiles, direction: direction)
        let (allTargetPositions, allMergeInstructions, moved) = moveResult
        
        if moved {
            // Start the animation sequence
            animationState = .animatingMove
            
            // Stage 1: Animate sliding all tiles to their new positions
            withAnimation(.easeInOut(duration: self.animationDurationSlide)) {
                for index in tiles.indices {
                    if let target = allTargetPositions[tiles[index].id] {
                        tiles[index].row = target.row
                        tiles[index].col = target.col
                    }
                }
            }
            
            // Stage 2: After slide completes, perform merges
            AnimationHelper.performAfterAnimation(duration: animationDurationSlide) {
                self.animationState = .animatingMerge
                self.performMerges(mergeInstructions: allMergeInstructions)
            }
        } else {
            // If no move occurred, remove the state saved for undo
            _ = undoStack.popLast()
//            showGameMessage("No move possible")
        }
    }
    
    // Perform merges with animation
    private func performMerges(mergeInstructions: [MergeInstruction]) {
        // Track highest value merged for messaging
        var highestMergedValue = 0
        
        for merge in mergeInstructions {
            if let mainIndex = self.tiles.firstIndex(where: { $0.id == merge.mainTileID }) {
                self.tiles[mainIndex].value = merge.newValue
                if merge.newValue > highestMergedValue {
                    highestMergedValue = merge.newValue
                }
            }
            
            withAnimation(.easeInOut(duration: self.animationDurationShowHide)) {
                self.tiles.removeAll { $0.id == merge.mergingTileID }
            }
        }
        
        // Show message for significant merges
        if highestMergedValue > previousHighMerge {
            showGameMessage("\(highestMergedValue)!", duration: 2.0)
            previousHighMerge = highestMergedValue
        }
        
        // After merges complete, finalize the move
        AnimationHelper.performAfterAnimation(duration: animationDurationShowHide) {
            self.animationState = .idle
            self.addRandomTile()
        }
    }
    
    // MARK: - Cheats
    func undo() {
        guard animationState == .idle else { return }
        
        if let previousState = undoStack.popLast() {
            withAnimation(.easeInOut(duration: self.animationDurationShowHide)) {
                tiles = previousState
            }
            undosUsed += 1
//            showGameMessage("Move Undone")
        }
    }
    
    func forceTile() {
        guard animationState == .idle else { return }
        
        let emptyPositions = boardLogic.getEmptyPositions(tiles: tiles)
        guard !emptyPositions.isEmpty, let pos = emptyPositions.randomElement() else { return }
        let tile = Tile(
            id: UUID(),
            value: gameLevel.nextTileValue,
            row: pos.row,
            col: pos.col
        )
        withAnimation(.easeInOut(duration: self.animationDurationShowHide)) {
            tiles.append(tile)
        }
        
        manual4sUsed += 1
    }
    
    func setPerfectBoard() {
        stopTimer()
        tiles = boardLogic.generatePerfectBoard()
        startTimer()
    }

    // MARK: - Edit Mode
    func toggleEditMode() {
        isEditMode.toggle()
        if isEditMode {
            showGameMessage("Edit Mode: Tap tiles to delete them", duration: 2.0)
        }
    }
    
    func deleteTile(id: UUID) {
        guard isEditMode else { return }
        
        withAnimation(.easeInOut(duration: self.animationDurationShowHide)) {
            tiles.removeAll { $0.id == id }
        }
    }
    
    // MARK: - Overlay Message
    func showGameMessage(_ message: String, duration: Double = 1.5) {
        // Cancel any existing message task
        overlayMessageTask?.cancel()
        
        // Set and show the new message
        overlayMessage = message
        showOverlayMessage = true
        
        // Create a new task to hide the message after the specified duration
        overlayMessageTask = Task { @MainActor in
            do {
                try await Task.sleep(for: .seconds(duration))
                if !Task.isCancelled {
                    showOverlayMessage = false
                }
            } catch {
                // Task was cancelled, do nothing
            }
        }
    }
    
}

