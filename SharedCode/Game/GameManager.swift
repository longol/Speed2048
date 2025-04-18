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
    @Published var boardSize: Int = 4 {
        didSet {
            if oldValue != boardSize {
                boardLogic = BoardLogic(boardSize: boardSize)
                newGame()
            }
        }
    }
    
    // UI state
    @Published var statusMessage: String = ""
    @Published var showVersionChoiceAlert: Bool = false
    
    // Private state
    private var fetchedCloudGameState: GameState? = nil
    private var timer: Timer? = nil
    
    // Game animation state
    enum GameAnimationState {
        case idle
        case animatingMove
        case animatingMerge
    }
    
    private var animationState: GameAnimationState = .idle
    
    var gameState: GameState {
        return GameState(
            tiles: tiles,
            seconds: seconds,
            undoStack: undoStack,
            gameLevel: gameLevel,
            fastAnimations: fastAnimations,
            undosUsed: undosUsed,
            manual4sUsed: manual4sUsed,
            boardSize: boardSize
        )
    }
    
    init() {
        Task {
            await loadGameStateLocally()
            await checkCloudVersion()
        }
    }
    
    // MARK: - Game Data Management
    func checkCloudVersion() async {
        updateStatusMessage("Checking cloud")
        do {
            let cloudState = try await dataManager.fetchGameStateFromCloud()
            let cloudTotalScore = cloudState.tiles.reduce(0) { $0 + $1.value }
            
            if cloudTotalScore > totalScore {
                fetchedCloudGameState = cloudState
                self.showVersionChoiceAlert = true
                updateStatusMessage("Found higher scored game")
            } else {
                updateStatusMessage("Local game is current")
            }
        } catch {
            updateStatusMessage(error.localizedDescription)
        }
    }
    
    func loadGameStateLocally() async {
        updateStatusMessage("Loading local game")
        do {
            let gameState = try await dataManager.loadGameStateLocally()
            applyGameState(gameState)
            updateStatusMessage("Loaded local game")
        } catch {
            updateStatusMessage(error.localizedDescription)
        }
    }
    
    func saveGameState() async {
        stopTimer()
        updateStatusMessage("Saving game")
        do {
            try await dataManager.saveGameStateLocally(gameState: gameState)
            updateStatusMessage("Saved locally, now saving to cloud")
            try await dataManager.saveGameStateToCloud(gameState: gameState)
            updateStatusMessage("Saved to cloud")
        } catch {
            updateStatusMessage(error.localizedDescription)
        }
    }
    
    func applyVersionChoice(useCloud: Bool) {
        if useCloud, let cloudGameState = fetchedCloudGameState {
            updateStatusMessage("Applying cloud version")
            applyGameState(cloudGameState)
        } else if !useCloud {
            updateStatusMessage("Keeping local version")
        } else {
            updateStatusMessage("Game up to date")
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
    
    func updateStatusMessage(_ message: String) {
        self.statusMessage = message
        print("CLOUD: \(message)")
        Task { @MainActor in
            try await Task.sleep(nanoseconds: 2_000_000_000)
            self.statusMessage = ""
        }
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
        stopTimer()
        tiles = []
        undoStack = []
        seconds = 0
        undosUsed = 0
        manual4sUsed = 0
        addRandomTile()
        addRandomTile()
        startTimer()
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
        }
    }
    
    // Perform merges with animation
    private func performMerges(mergeInstructions: [MergeInstruction]) {
        for merge in mergeInstructions {
            if let mainIndex = self.tiles.firstIndex(where: { $0.id == merge.mainTileID }) {
                self.tiles[mainIndex].value = merge.newValue
            }
            
            withAnimation(.easeInOut(duration: self.animationDurationShowHide)) {
                self.tiles.removeAll { $0.id == merge.mergingTileID }
            }
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
        }
    }
    
    func forceTile() {
        guard animationState == .idle else { return }
        
        let emptyPositions = boardLogic.getEmptyPositions(tiles: tiles)
        guard !emptyPositions.isEmpty, let pos = emptyPositions.randomElement() else { return }
        let tile = Tile(id: UUID(), value: 4, row: pos.row, col: pos.col)
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
}

