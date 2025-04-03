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

    private var gameStateFileURL: URL {
        let fileManager = FileManager.default
        let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return directory.appendingPathComponent("Speed2048.json")
    }

    @Published var gameLevel: GameLevel = .regular
    @Published var tiles: [Tile] = []
    @Published var seconds: Int = 0
    
    @Published var animationDurationSlide: Double = 0.08
    @Published var animationDurationShowHide: Double = 0.02
    @Published var boardSize = 4
    @Published var tileStartCountValue = 8

    @Published var penaltyAlert: String = "Let's get started!"
    private var isAnimating: Bool = false

    private var undoStack: [[Tile]] = []
    private var timer: Timer? = nil

    var tileDurations: [Int: [Int]] = [:]        // E.g., [8: [10, 9], 16: [29]]
    var lastTileTimestamps: [Int: Int] = [:]       // E.g., [8: 15, 16: 40]

    let container = CKContainer(identifier: "iCloud.Speed2048")
    var privateDatabase: CKDatabase {
        return container.privateCloudDatabase
    }
    
    init() {
        loadGameState()
    }

    // MARK: GAME MECHANICS
    func newGame() {
        tiles = []
        undoStack = []
        stopTimer() // Ensure the timer is stopped before starting a new game
        seconds = 0
        tileDurations = [:]
        lastTileTimestamps = [:]
        addRandomTile()
        addRandomTile()
        startTimer() // Start the timer only after the game is initialized
    }
    
    // Start a new game with the perfect board setup.
    func newPerfectGame() {
        stopTimer()
        
        // Clear previous game state
        tiles = []
        undoStack = []
        seconds = 0
//        cheatsUsed = 0
//        undosUsed = 0
//        manual4sUsed = 0
        tileDurations = [:]
        lastTileTimestamps = [:]
        
        // Define perfect board tile values
        let perfectBoardValues: [[Int]] = [
            [131072, 65536, 32768, 16384],
            [8192, 4096, 2048, 1024],
            [512, 256, 128, 64],
            [32, 16, 8, 4]
        ]
        
        // Populate tiles with the perfect board setup
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                let value = perfectBoardValues[row][col]
                let tile = Tile(id: UUID(), value: value, row: row, col: col)
                tiles.append(tile)
            }
        }

        // Start timer if you still want to track time after setup
        startTimer()
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
        tileAdded(value) // Track timing for the added tile
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
    
    /// Public move function. Saves an undo snapshot and, if any tile moved/merged,
    /// adds a new tile after the move.
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

    /// Unified move function that handles all four directions in two stages:
    ///   1. Animate sliding tiles to their new positions.
    ///   2. After sliding is done, merge tiles and remove the merging tiles.
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
                    }
                    self.tileAdded(merge.newValue) // Track timing for the merged tile
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

    /// Undo the last move.
    func undo() {
        if let previousState = undoStack.popLast() {
            withAnimation(.easeInOut(duration: self.animationDurationShowHide)) {
                tiles = previousState
            }
            showPenaltyAlert(.undoPenalty)
        }
    }

    /// Immediately adds a tile with a value of 4.
    func forceTile() {
        let emptyPositions = getEmptyPositions()
        guard !emptyPositions.isEmpty, let pos = emptyPositions.randomElement() else { return }
        let tile = Tile(id: UUID(), value: 4, row: pos.row, col: pos.col)
        withAnimation(.easeInOut(duration: self.animationDurationShowHide)) {
            tiles.append(tile)
        }
        showPenaltyAlert(.addFourPenalty)
        tileAdded(tile.value) // Track timing for the added tile
    }
    
    // MARK: SCORING

    /// Show a penalty alert and reset it after a delay.
    func showPenaltyAlert(_ penalty: PenaltyType) {
        let amount = penalty.amount(withLevel: gameLevel)
        penaltyAlert = "\(penalty.rawValue) +\(amount)s!"
        seconds += amount
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // Reset after 2 seconds
            self.penaltyAlert = "Keep going!"
        }
    }

    func tileAdded(_ tileValue: Int) {
        guard tileValue >= tileStartCountValue else { return }
        
        var interval = seconds
        // If this tile has been produced before, compute the time interval.
        if let lastTime = lastTileTimestamps[tileValue] {
            interval = seconds - lastTime
        }
        
        tileDurations[tileValue, default: []].append(interval)

        // Record the current timestamp for this tile.
        lastTileTimestamps[tileValue] = seconds
    }

    // Returns the average time (in seconds) for a given tile value.
    func averageTime(for tileValue: Int) -> Double? {
        guard let durations = tileDurations[tileValue], !durations.isEmpty else { return nil }
        let sum = durations.reduce(0, +)
        return Double(sum) / Double(durations.count)
    }

    // Returns the seconds since the last appearance of the given tile value.
    func secondsSinceLast(for tileValue: Int) -> Int? {
        guard let lastTime = lastTileTimestamps[tileValue] else { return nil }
        return seconds - lastTime
    }

    // A helper function to produce a display string for each tile's stats.
    func displayStats(for tileValue: Int) -> String {
        if let avg = averageTime(for: tileValue) {
            let current = secondsSinceLast(for: tileValue) ?? 0
            // Format as: "Tile 8: Beat 9.5 sec | Current: 3 sec"
            return "Tile \(tileValue): Beat \(String(format: "%.1f", avg)) sec | Current: \(current) sec"
        } else {
            return "Tile \(tileValue): No data yet"
        }
    }
    
    // Returns a formatted string for the average time to produce a given tile.
    func averageTimeString(for tileValue: Int) -> String {
        if let avg = averageTime(for: tileValue) {
            return Int(avg).formattedAsTime
        } else {
            return "No data"
        }
    }

    // Returns a formatted string for the current time (seconds since last appearance) of a given tile.
    func currentTimeString(for tileValue: Int) -> String {
        if let current = secondsSinceLast(for: tileValue) {
            return current.formattedAsTime
        } else {
            return "N/A"
        }
    }
    
    // MARK: DATA MANAGEMENT

    func saveGameStateLocally() {
        stopTimer() // Stop the timer when saving the game state

        let gameState = GameState(
            tiles: tiles,
            seconds: seconds,
            undoStack: undoStack,
            gameLevel: gameLevel,
            animationDurationSlide: animationDurationSlide,
            animationDurationShowHide: animationDurationShowHide,
            boardSize: boardSize,
            tileDurations: tileDurations,
            lastTileTimestamps: lastTileTimestamps
        )
        if let data = try? JSONEncoder().encode(gameState) {
            do {
                try data.write(to: gameStateFileURL, options: .atomic)
                print("Game state saved to \(gameStateFileURL)")
            } catch {
                print("Failed to save game state: \(error.localizedDescription)")
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
                self.animationDurationSlide = gameState.animationDurationSlide
                self.animationDurationShowHide = gameState.animationDurationShowHide
                self.boardSize = gameState.boardSize
                self.tileDurations = gameState.tileDurations
                self.lastTileTimestamps = gameState.lastTileTimestamps

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
        
        let record = CKRecord(recordType: "GameState", recordID: CKRecord.ID(recordName: "currentGame"))
        let gameState = GameState(
            tiles: tiles,
            seconds: seconds,
            undoStack: undoStack,
            gameLevel: gameLevel,
            animationDurationSlide: animationDurationSlide,
            animationDurationShowHide: animationDurationShowHide,
            boardSize: boardSize,
            tileDurations: tileDurations,
            lastTileTimestamps: lastTileTimestamps
        )
        
        do {
            let data = try JSONEncoder().encode(gameState)
            record["stateData"] = data
            privateDatabase.save(record) { (savedRecord, error) in
                if let error = error {
                    print("Failed to save to CloudKit: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.saveGameStateLocally()
                    }
                } else {
                    print("Game state saved to CloudKit")
                }
            }
        } catch {
            print("Failed to encode game state: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.saveGameStateLocally()
            }
        }
    }

    // Load the game state from CloudKit's private database
    func loadGameState() {
        
        let recordID = CKRecord.ID(recordName: "currentGame")
    
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
                    self.animationDurationSlide = gameState.animationDurationSlide
                    self.animationDurationShowHide = gameState.animationDurationShowHide
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
}


