//
//  Models.swift
//  TwentyFortyEight
//
//  Created by Lucas Longo on 2/17/25.
//

import SwiftUI
import CloudKit

/// The view model that holds the game state.
class GameViewModel: ObservableObject {

    // MARK: Scoring
    @Published var tileDurations: [Int: [Int]] = [:]        // E.g., [8: [10, 9], 16: [29]]
    @Published var seconds: Int = 0
    @Published var gameLevel: GameLevel = .regular
    @Published var fastAnimations: Bool = false
    @Published var tiles: [Tile] = []
    
    @Published var totalScore: Int = 0
    @Published var cheatsUsed: Int = 0
    @Published var undosUsed: Int = 0
    @Published var manual4sUsed: Int = 0

    private var lastTileTimestamps: [Int: Int] = [:]       // E.g., [8: 15, 16: 40]

    // MARK: Game Settings
    var animationDurationSlide: Double {
        return fastAnimations ? 0.01 : 0.1
    }
    var animationDurationShowHide: Double {
        return fastAnimations ? 0.01 : 0.1
    }
    
    private var boardSize = 4
    private var tileStartCountValue = 8
    
    // MARK: Game Mechanics
    private var isAnimating: Bool = false
    private var undoStack: [[Tile]] = []
    private var timer: Timer? = nil

    // MARK: CloudKit and Data Management
    private let container = CKContainer(identifier: "iCloud.com.lucaslongo.Quest131072")
    private let recordID = CKRecord.ID(recordName: "currentGame")

    private var privateDatabase: CKDatabase {
        return container.privateCloudDatabase
    }
    private var gameStateFileURL: URL {
        let fileManager = FileManager.default
        let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return directory.appendingPathComponent("Speed2048.json")
    }

    @Published var showVersionChoiceAlert: Bool = false
    var fetchedCloudGameState: GameState? = nil
    init() {
        checkCloudVersion()
    }

    // MARK: GAME MECHANICS
    func newGame() {
        stopTimer()
        tiles = []
        undoStack = []
        seconds = 0
        cheatsUsed = 0
        undosUsed = 0
        manual4sUsed = 0
        tileDurations = [:]
        lastTileTimestamps = [:]
        addRandomTile()
        addRandomTile()
        startTimer() // Start the timer only after the game is initialized
    }

    func checkCloudVersion() {

        privateDatabase.fetch(withRecordID: recordID) { (record, error) in
            DispatchQueue.main.async {
                if let record = record,
                   let data = record["stateData"] as? Data,
                   let cloudState = try? JSONDecoder().decode(GameState.self, from: data) {
                    // Cloud game found – store it and notify the view.
                    self.fetchedCloudGameState = cloudState
                    self.showVersionChoiceAlert = true
                } else {
                    // No cloud state found; start a new local game.
                    self.newGame()
                }
            }
        }
    }

    func applyVersionChoice(useCloud: Bool) {
        if useCloud, let cloudGameState = fetchedCloudGameState {
            applyGameState(cloudGameState)
        } else {
            self.newGame()
            self.saveGameState() // Overwrite cloud with current game state.
        }
        // Reset temporary variables.
        self.showVersionChoiceAlert = false
        self.fetchedCloudGameState = nil
    }
    
    func applyGameState(_ gameState: GameState) {
        self.tiles = gameState.tiles
        self.seconds = gameState.seconds
        self.undoStack = gameState.undoStack
        self.gameLevel = gameState.gameLevel
        self.fastAnimations = gameState.fastAnimations
        self.boardSize = gameState.boardSize
        self.tileDurations = gameState.tileDurations
        self.lastTileTimestamps = gameState.lastTileTimestamps
        self.cheatsUsed = gameState.cheatsUsed
        self.undosUsed = gameState.undosUsed
        self.manual4sUsed = gameState.manual4sUsed
        
        if !self.tiles.isEmpty { self.startTimer() }
    }
    
    func startTimer() {
        guard timer == nil else { return } // Ensure the timer is not already running
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if !self.tiles.isEmpty { // Only increment seconds if the game is active
                self.seconds += 1
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func addRandomTile() {
        let emptyPositions = getEmptyPositions()
        guard !emptyPositions.isEmpty, let pos = emptyPositions.randomElement() else { return }
        
        // Determine the value based on the probability of fours
        let value = Double.random(in: 0..<1) < gameLevel.probabilityOfFours ? 4 : 2
        let tile = Tile(id: UUID(), value: value, row: pos.row, col: pos.col)
        
        withAnimation(.easeInOut(duration: self.animationDurationShowHide)) {
            tiles.append(tile)
        }
    }
    
    func getEmptyPositions() -> [(row: Int, col: Int)] {
        var positions: [(Int, Int)] = []
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                if !tiles.contains(where: { $0.row == row && $0.col == col }) {
                    positions.append((row, col))
                }
            }
        }
        return positions
    }
    
    func move(_ direction: Direction) {
        if isAnimating { return }
        // Save current state for undo.
        undoStack.append(tiles.map { $0 })
        let moved = moveUnified(direction)
        if moved {
            addRandomTile()
        } else {
            _ = undoStack.popLast()
        }
    }

    func moveUnified(_ direction: Direction) -> Bool {
        guard !isAnimating else { return false }
        isAnimating = true

        var moved = false
        var mergeInstructions: [MergeInstruction] = []
        var targetPositions: [UUID: (row: Int, col: Int)] = [:]
        
        // Determine if the move is horizontal (left/right) or vertical (up/down).
        let isHorizontal = (direction == .left || direction == .right)
        // For left/up, we slide toward index 0; for right/down, toward boardSize - 1.
        let ascending = (direction == .left || direction == .up)
        let targetStart = ascending ? 0 : boardSize - 1
        let targetStep = ascending ? 1 : -1
        
        // Process each line (row for horizontal moves, column for vertical moves).
        for lineIndex in 0..<boardSize {
            let lineTiles: [Tile] = {
                if isHorizontal {
                    return tiles.filter { $0.row == lineIndex }
                } else {
                    return tiles.filter { $0.col == lineIndex }
                }
            }()
            
            if lineTiles.isEmpty { continue }
            
            // Sort the tiles in the direction of movement.
            let sortedTiles = lineTiles.sorted {
                if ascending {
                    return isHorizontal ? $0.col < $1.col : $0.row < $1.row
                } else {
                    return isHorizontal ? $0.col > $1.col : $0.row > $1.row
                }
            }
            
            var pos = targetStart
            var i = 0
            while i < sortedTiles.count {
                let currentTile = sortedTiles[i]
                // Check if next tile exists and is mergeable.
                if i < sortedTiles.count - 1, currentTile.value == sortedTiles[i+1].value {
                    let newValue = currentTile.value * 2
                    // Both tiles will slide to the same target position.
                    if isHorizontal {
                        targetPositions[currentTile.id] = (row: lineIndex, col: pos)
                        targetPositions[sortedTiles[i+1].id] = (row: lineIndex, col: pos)
                        // Check if either tile is not already at the target.
                        if currentTile.col != pos || sortedTiles[i+1].col != pos {
                            moved = true
                        }
                    } else {
                        targetPositions[currentTile.id] = (row: pos, col: lineIndex)
                        targetPositions[sortedTiles[i+1].id] = (row: pos, col: lineIndex)
                        if currentTile.row != pos || sortedTiles[i+1].row != pos {
                            moved = true
                        }
                    }
                    mergeInstructions.append(MergeInstruction(mainTileID: currentTile.id,
                                                              mergingTileID: sortedTiles[i+1].id,
                                                              newValue: newValue))
                    i += 2  // Skip the next tile since it will be merged.
                } else {
                    // No merge: simply slide the tile to the target position.
                    if isHorizontal {
                        targetPositions[currentTile.id] = (row: lineIndex, col: pos)
                        if currentTile.col != pos { moved = true }
                    } else {
                        targetPositions[currentTile.id] = (row: pos, col: lineIndex)
                        if currentTile.row != pos { moved = true }
                    }
                    i += 1
                }
                pos += targetStep
            }
        }
        
        // Stage 1: Animate sliding all tiles to their new positions.
        withAnimation(.easeInOut(duration: self.animationDurationShowHide)) {
            for index in tiles.indices {
                if let target = targetPositions[tiles[index].id] {
                    tiles[index].row = target.row
                    tiles[index].col = target.col
                }
            }
        }
        
        // Stage 2: After the slide animation completes, perform the merges and removals.
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDurationSlide) {
            for merge in mergeInstructions {
                // Update the main tile's value to reflect the merge.
                if let mainIndex = self.tiles.firstIndex(where: { $0.id == merge.mainTileID }) {
                    withAnimation(.easeInOut(duration: self.animationDurationShowHide)) {
                        self.tiles[mainIndex].value = merge.newValue
                        self.totalScore += merge.newValue
                    }
                }
                
                // Animate the removal of the merging tile.
                withAnimation(.easeInOut(duration: self.animationDurationShowHide)) {
                    self.tiles.removeAll { $0.id == merge.mergingTileID }
                }
            }

            // Allow new moves after all animations complete.
            DispatchQueue.main.asyncAfter(deadline: .now() + self.animationDurationShowHide) {
                self.isAnimating = false
            }            
        }
        
        return moved
    }
    
    // MARK: CHEATS
    func undo() {
        if let previousState = undoStack.popLast() {
            withAnimation(.easeInOut(duration: self.animationDurationShowHide)) {
                tiles = previousState
            }
            undosUsed += 1
            cheatsUsed += 1
        }
    }

    func forceTile() {
        let emptyPositions = getEmptyPositions()
        guard !emptyPositions.isEmpty, let pos = emptyPositions.randomElement() else { return }
        let tile = Tile(id: UUID(), value: 4, row: pos.row, col: pos.col)
        withAnimation(.easeInOut(duration: self.animationDurationShowHide)) {
            tiles.append(tile)
        }
        
        manual4sUsed += 1
        cheatsUsed += 1

    }

    // MARK: DATA MANAGEMENT
    func loadGameState() {
        
        privateDatabase.fetch(withRecordID: recordID) { (record, error) in
            if let error = error {
                print("Failed to load from CloudKit: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.loadGameStateLocally()
                }
                return
            }
            
            guard let record = record, let data = record["stateData"] as? Data else {
                DispatchQueue.main.async {
                    self.loadGameStateLocally()
                }
                return
            }
            
            do {
                let gameState = try JSONDecoder().decode(GameState.self, from: data)
                DispatchQueue.main.async {
                    self.tiles = gameState.tiles
                    self.seconds = gameState.seconds
                    self.undoStack = gameState.undoStack
                    self.gameLevel = gameState.gameLevel
                    self.fastAnimations = gameState.fastAnimations
                    self.boardSize = gameState.boardSize
                    self.tileDurations = gameState.tileDurations
                    self.lastTileTimestamps = gameState.lastTileTimestamps
                    
                    if !self.tiles.isEmpty {
                        self.startTimer() // Resume timer if game is active
                    }
                    print("Game state loaded from CloudKit")
                }
            } catch {
                print("Failed to decode game state: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.loadGameStateLocally()
                }
            }
        }
    }
    func loadGameStateLocally() {
        do {
            let data = try Data(contentsOf: gameStateFileURL)
            if let gameState = try? JSONDecoder().decode(GameState.self, from: data) {
                self.tiles = gameState.tiles
                self.seconds = gameState.seconds
                self.undoStack = gameState.undoStack
                self.gameLevel = gameState.gameLevel
                self.fastAnimations = gameState.fastAnimations
                self.boardSize = gameState.boardSize
                self.tileDurations = gameState.tileDurations
                self.lastTileTimestamps = gameState.lastTileTimestamps
                self.cheatsUsed = gameState.cheatsUsed
                self.undosUsed = gameState.undosUsed
                self.manual4sUsed = gameState.manual4sUsed

                if !tiles.isEmpty { startTimer() } // Start the timer only if there is an active game
                print("Game state loaded from \(gameStateFileURL)")
            } else {
                newGame() // If decoding fails, start a new game
            }
        } catch {
            print("No saved game state found, starting a new game.")
            newGame() // If no saved state exists, start a new game
        }
    }
    func saveGameState() {
        stopTimer() // Pause the timer during save to avoid inconsistencies
        
        let gameState = GameState(
            tiles: tiles,
            seconds: seconds,
            undoStack: undoStack,
            gameLevel: gameLevel,
            fastAnimations: fastAnimations,
            boardSize: boardSize,
            tileDurations: tileDurations,
            lastTileTimestamps: lastTileTimestamps,
            cheatsUsed: cheatsUsed,
            undosUsed: undosUsed,
            manual4sUsed: manual4sUsed
        )

        do {
            let data = try JSONEncoder().encode(gameState)
            
            // Step 1: Try to fetch the existing record
            privateDatabase.fetch(withRecordID: recordID) { (record, error) in
                let recordToSave: CKRecord
                if let existingRecord = record {
                    // If the record exists, use it
                    recordToSave = existingRecord
                } else {
                    // If it doesn't exist (or fetch failed for another reason), create a new one
                    recordToSave = CKRecord(recordType: "GameState", recordID: self.recordID)
                }
                
                // Step 2: Set the updated data
                recordToSave["stateData"] = data
                
                // Step 3: Save the record (this will update if it exists, or create if it doesn't)
                self.privateDatabase.save(recordToSave) { (savedRecord, saveError) in
                    DispatchQueue.main.async {
                        if let error = saveError {
                            print("Failed to save to CloudKit: \(error.localizedDescription)")
                            self.saveGameStateLocally(gameState: gameState)
                        } else {
                            print("Game state saved to CloudKit")
                        }
                    }
                }
            }
        } catch {
            print("Failed to encode game state: \(error.localizedDescription)")
        }
    }
    func saveGameStateLocally(gameState: GameState) {
        stopTimer() // Stop the timer when saving the game state

        if let data = try? JSONEncoder().encode(gameState) {
            do {
                try data.write(to: gameStateFileURL, options: .atomic)
                print("Game state saved to \(gameStateFileURL)")
            } catch {
                print("Failed to save game state: \(error.localizedDescription)")
            }
        }
    }

}


