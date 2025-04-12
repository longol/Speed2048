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
    @Published var seconds: Int = 0
    @Published var gameLevel: GameLevel = .regular
    @Published var fastAnimations: Bool = false
    @Published var tiles: [Tile] = []
    @Published var undoStack: [[Tile]] = []
    @Published var undosUsed: Int = 0
    @Published var manual4sUsed: Int = 0
    
    @Published var statusMessage: String = "" // Replaced cloud tuple

    var totalScore: Int {
        return tiles.reduce(0) { $0 + $1.value }
    }
    var cheatsUsed: Int {
        return undosUsed + manual4sUsed
    }
    
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
        return directory.appendingPathComponent("Quest131072.json")
    }

    @Published var showVersionChoiceAlert: Bool = false
    var fetchedCloudGameState: GameState? = nil
    
    init() {
        loadGameStateLocally() // Load local state first
        checkCloudVersion()    // Then check cloud
    }

    // MARK: GAME MECHANICS
    func newGame() {
        stopTimer()
        tiles = []
        undoStack = []
        seconds = 0
        undosUsed = 0
        manual4sUsed = 0
        addRandomTile()
        addRandomTile()
        startTimer() // Start the timer only after the game is initialized
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
            DispatchQueue.main.async { // Ensure updates happen on the main thread
                for merge in mergeInstructions {
                    // Update the main tile's value to reflect the merge.
                    if let mainIndex = self.tiles.firstIndex(where: { $0.id == merge.mainTileID }) {
                        withAnimation(.easeInOut(duration: self.animationDurationShowHide)) {
                            self.tiles[mainIndex].value = merge.newValue
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

    }

    func setPerfectBoard() {
        stopTimer()
        tiles = [
            Tile(id: UUID(), value: 131072, row: 0, col: 0),
            Tile(id: UUID(), value: 65536, row: 0, col: 1),
            Tile(id: UUID(), value: 32768, row: 0, col: 2),
            Tile(id: UUID(), value: 16384, row: 0, col: 3),
            Tile(id: UUID(), value: 8192, row: 1, col: 0),
            Tile(id: UUID(), value: 4096, row: 1, col: 1),
            Tile(id: UUID(), value: 2048, row: 1, col: 2),
            Tile(id: UUID(), value: 1024, row: 1, col: 3),
            Tile(id: UUID(), value: 512, row: 2, col: 0),
            Tile(id: UUID(), value: 256, row: 2, col: 1),
            Tile(id: UUID(), value: 128, row: 2, col: 2),
            Tile(id: UUID(), value: 64, row: 2, col: 3),
            Tile(id: UUID(), value: 32, row: 3, col: 0),
            Tile(id: UUID(), value: 16, row: 3, col: 1),
            Tile(id: UUID(), value: 8, row: 3, col: 2),
            Tile(id: UUID(), value: 4, row: 3, col: 3)
        ]
        startTimer()
    }

    // MARK: DATA MANAGEMENT

    /// Helper to update status message ensuring it's on the main thread.
    private func updateStatusMessage(_ message: String) {
        DispatchQueue.main.async {
            self.statusMessage = message
            // Empty the message after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.statusMessage = ""
            }
        }
    }

    func checkCloudVersion() {
        // loadGameStateLocally() // Moved to init

        updateStatusMessage("Checking cloud")

        fetchGameStateFromCloud { result in
            // This completion handler already runs on the main thread due to fetchGameStateFromCloud's implementation
            switch result {
            case .success(let cloudState):
                let cloudTotalScore = cloudState.tiles.reduce(0) { $0 + $1.value }
                
                if cloudTotalScore > self.totalScore {
                    self.fetchedCloudGameState = cloudState
                    // Ensure UI updates are on the main thread
                    DispatchQueue.main.async {
                        self.showVersionChoiceAlert = true
                    }
                    self.updateStatusMessage("Found higher scored game") // Update status
                } else {
                    self.updateStatusMessage("Local game is current") // Update status
                }
            case .failure(let error):
                // Determine message based on error
                let message: String
                if let ckError = error as? CKError, ckError.code == .notAuthenticated {
                    message = "iCloud account not set up"
                } else {
                    message = "Cloud load failed"
                    print("Cloud load failed: \(error.localizedDescription)")
                }
                self.updateStatusMessage(message) // Update status
            }
        }
    }

    func fetchGameStateFromCloud(completion: @escaping (Result<GameState, Error>) -> Void) {
        updateStatusMessage("Fetching cloud data")

        privateDatabase.fetch(withRecordID: recordID) { (record, error) in
            // Process the result on the background thread first
            let result: Result<GameState, Error>
            var message: String = "" // Temporary message holder

            if let ckError = error as? CKError, ckError.code == .notAuthenticated {
                message = "iCloud account not setup"
                result = .failure(NSError(domain: "GameViewModel", code: 3, userInfo: [NSLocalizedDescriptionKey: "iCloud account not set up"]))
            } else if let record = record,
                      let asset = record["stateAsset"] as? CKAsset,
                      let fileURL = asset.fileURL {
                do {
                    // Perform file reading and decoding on the background thread
                    let data = try Data(contentsOf: fileURL)
                    if let cloudState = try? JSONDecoder().decode(GameState.self, from: data) {
                        message = "Got cloud data"
                        result = .success(cloudState)
                    } else {
                        message = "Failed to decode cloud game state"
                        result = .failure(NSError(domain: "GameViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode cloud game state"]))
                    }
                } catch {
                    message = "Corrupted cloud data"
                    result = .failure(error)
                }
            } else {
                // Handle fetch error or missing record/asset
                message = "No cloud game found" // More user-friendly message
                result = .failure(error ?? NSError(domain: "GameViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch cloud record or asset"]))
            }

            // Now dispatch the UI update and completion call to the main thread
            DispatchQueue.main.async {
                // Update status message *before* calling completion,
                // in case completion triggers further status updates.
                self.updateStatusMessage(message) // Update message
                completion(result)
            }
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
        self.showVersionChoiceAlert = false
        self.fetchedCloudGameState = nil
    }
    
    func applyGameState(_ gameState: GameState) {
        
        self.tiles = gameState.tiles
        self.seconds = gameState.seconds
        self.undoStack = gameState.undoStack
        self.gameLevel = gameState.gameLevel
        self.fastAnimations = gameState.fastAnimations
        self.undosUsed = gameState.undosUsed
        self.manual4sUsed = gameState.manual4sUsed
        
        if !self.tiles.isEmpty { self.startTimer() }
    }

    func loadGameStateLocally() {
        updateStatusMessage("Loading local game") // Indicate loading start
        do {
            let data = try Data(contentsOf: gameStateFileURL)
            if let gameState = try? JSONDecoder().decode(GameState.self, from: data) {
                applyGameState(gameState) // Use applyGameState
                updateStatusMessage("Local game loaded")
            } else {
                updateStatusMessage("Failed to decode local game, starting new")
                newGame() // If decoding fails, start a new game
            }
        } catch {
            updateStatusMessage("No local game found, starting new")
            newGame() // If no saved state exists, start a new game
        }
    }

    func saveGameState() {
        stopTimer() // Pause the timer during save

        updateStatusMessage("Saving game")
        
        let gameState = GameState(
            tiles: tiles,
            seconds: seconds,
            undoStack: undoStack,
            gameLevel: gameLevel,
            fastAnimations: fastAnimations,
            undosUsed: undosUsed,
            manual4sUsed: manual4sUsed
        )

        // Save locally first
        saveGameStateLocally(gameState: gameState)
        
        // Then attempt to save to CloudKit
        do {
            let data = try JSONEncoder().encode(gameState)
            // Use a unique temporary file URL for each save attempt
            let tempFileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
            try data.write(to: tempFileURL, options: .atomic)
            
            updateStatusMessage("Checking cloud before save")

            privateDatabase.fetch(withRecordID: recordID) { (record, error) in
                // This callback is on a background thread
                
                // Determine if we are updating or creating a new record
                let recordToSave: CKRecord
                if let existingRecord = record, error == nil {
                     self.updateStatusMessage("Updating cloud game")
                    recordToSave = existingRecord
                } else if let ckError = error as? CKError, ckError.code == .unknownItem {
                    // Record doesn't exist, create a new one
                    self.updateStatusMessage("Creating new cloud game")
                    recordToSave = CKRecord(recordType: "GameState", recordID: self.recordID)
                } else {
                    // Another fetch error occurred
                    self.updateStatusMessage("Cloud check failed: \(error?.localizedDescription ?? "Unknown error")")
                    // Clean up temporary file
                    try? FileManager.default.removeItem(at: tempFileURL)
                    return
                }

                recordToSave["stateAsset"] = CKAsset(fileURL: tempFileURL)

                self.privateDatabase.save(recordToSave) { (savedRecord, saveError) in
                    // This callback is on a background thread
                    
                    // Clean up the temporary file regardless of success or failure
                    try? FileManager.default.removeItem(at: tempFileURL)

                    if let saveError = saveError as? CKError, saveError.code == .serverRecordChanged {
                        self.updateStatusMessage("Cloud conflict detected, resolving...")
                        self.resolveCloudConflict(tempFileURL: tempFileURL) // Pass the *original* temp URL if needed, or re-encode
                    } else if let saveError = saveError {
                        self.updateStatusMessage("Cloud save failed: \(saveError.localizedDescription)")
                    } else {
                        self.updateStatusMessage("Saved to cloud")
                    }
                }
            }
        } catch {
             updateStatusMessage("Failed to prepare data for cloud save")
        }
    }

    
    private func resolveCloudConflict(tempFileURL: URL) {
        // Re-fetch the latest record
        updateStatusMessage("Re-fetching latest cloud game")
        privateDatabase.fetch(withRecordID: recordID) { (latestRecord, fetchError) in
            // Background thread
            guard let latestRecord = latestRecord, fetchError == nil else {
                self.updateStatusMessage("Conflict resolution failed (fetch)")
                print("Conflict resolution fetch failed: \(fetchError?.localizedDescription ?? "empty error")")
                return
            }

            // Re-encode the *current* game state to a *new* temporary file
            // because the original tempFileURL might have been cleaned up or is stale.
            let currentGameState = GameState(
                tiles: self.tiles, seconds: self.seconds, undoStack: self.undoStack,
                gameLevel: self.gameLevel, fastAnimations: self.fastAnimations,
                undosUsed: self.undosUsed, manual4sUsed: self.manual4sUsed
            )
            do {
                let data = try JSONEncoder().encode(currentGameState)
                let newTempFileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
                try data.write(to: newTempFileURL, options: .atomic)

                // Overwrite the cloud record with the current local state using the latest record's change tag
                latestRecord["stateAsset"] = CKAsset(fileURL: newTempFileURL)
                
                self.updateStatusMessage("Attempting conflict resolution save")

                self.privateDatabase.save(latestRecord) { (savedRecord, saveError) in
                    // Background thread
                    try? FileManager.default.removeItem(at: newTempFileURL) // Clean up new temp file

                    if let saveError = saveError {
                        self.updateStatusMessage("Conflict resolution save failed")
                        print("Conflict resolution save failed: \(saveError.localizedDescription)")
                    } else {
                        self.updateStatusMessage("Cloud conflict resolved (used local)")
                        print("Cloud conflict resolved using local state.")
                    }
                }
            } catch {
                 self.updateStatusMessage("Failed to prepare data for conflict resolution")
            }
        }
    }

    func saveGameStateLocally(gameState: GameState) {
        // stopTimer() // Removed: Called by saveGameState already

        // Don't overwrite the main status message if a cloud save is in progress.
        // Just log the local save status.
        // updateStatusMessage("Saving locally...") // Removed this line

        do {
            let data = try JSONEncoder().encode(gameState)
            try data.write(to: gameStateFileURL, options: .atomic)
            print("Local save successful.")
            // If no cloud save is happening, we could update the status, but
            // it's simpler to let the main saveGameState function handle the final status.
        } catch {
            print("Local save failed: \(error.localizedDescription)")
            // Update the main status message only if a more specific error isn't already shown.
            // This might still be overwritten by the cloud save result later.
            self.updateStatusMessage("Local save failed")
        }
    }

}


