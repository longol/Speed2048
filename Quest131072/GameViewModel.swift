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
    
    @Published var cloud: (loading: Bool, message: String) = (false,"")

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
//        checkCloudVersion()
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
    func checkCloudVersion() {
        loadGameStateLocally()

        cloud.loading = true
        cloud.message = "Checking cloud"

        fetchGameStateFromCloud { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let cloudState):
                    self.cloud.message = "Comparing scores"
                    print("Comparing scores")

                    // Compare scores and decide action
                    let cloudTotalScore = cloudState.tiles.reduce(0) { $0 + $1.value }
                    
                    if cloudTotalScore > self.totalScore {
                        // Cloud version has a higher score, prompt the user
                        self.fetchedCloudGameState = cloudState
                        self.showVersionChoiceAlert = true
                        self.cloud.message = "Which one do you want?"
                        print("Which one do you want?")
                    } else {
                        self.cloud.message = "Game up to date"
                        print("Game up to date")
                    }
                case .failure(let error):
                    if let ckError = error as? CKError, ckError.code == .notAuthenticated {
                        self.cloud.message = "iCloud account not set up"
                        print("iCloud account not set up")
                    } else {
                        self.cloud.message = "Cloud load failed"
                        print("Cloud load failed: \(error.localizedDescription)")
                    }
                }

                self.resetCloudMessage()
            }
        }
    }

    func fetchGameStateFromCloud(completion: @escaping (Result<GameState, Error>) -> Void) {
        cloud.loading = true
        cloud.message = "Fetching cloud data"

        privateDatabase.fetch(withRecordID: recordID) { (record, error) in
            DispatchQueue.main.async {
                if let error = error as? CKError, error.code == .notAuthenticated {
                    completion(.failure(NSError(domain: "GameViewModel", code: 3, userInfo: [NSLocalizedDescriptionKey: "iCloud account not set up"])))
                    return
                }

                if let record = record,
                   let asset = record["stateAsset"] as? CKAsset,
                   let fileURL = asset.fileURL {
                    do {
                        let data = try Data(contentsOf: fileURL)
                        if let cloudState = try? JSONDecoder().decode(GameState.self, from: data) {
                            completion(.success(cloudState))
                        } else {
                            completion(.failure(NSError(domain: "GameViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode cloud game state"])))
                        }
                    } catch {
                        completion(.failure(error))
                    }
                } else {
                    completion(.failure(error ?? NSError(domain: "GameViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch cloud record"])))
                }

                self.resetCloudMessage()
            }
        }
    }

    func applyVersionChoice(useCloud: Bool) {
        if useCloud, let cloudGameState = fetchedCloudGameState {
            applyGameState(cloudGameState)

            cloud.loading = true
            cloud.message = "Loading cloud"
            resetCloudMessage()
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
        
        do {
            let data = try Data(contentsOf: gameStateFileURL)
            if let gameState = try? JSONDecoder().decode(GameState.self, from: data) {
                self.tiles = gameState.tiles
                self.seconds = gameState.seconds
                self.undoStack = gameState.undoStack
                self.gameLevel = gameState.gameLevel
                self.fastAnimations = gameState.fastAnimations
                self.undosUsed = gameState.undosUsed
                self.manual4sUsed = gameState.manual4sUsed

                if !tiles.isEmpty { startTimer() } // Start the timer only if there is an active game
//                self.cloud.message = "Local game loaded"
//                print("Local game loaded")
            } else {
                newGame() // If decoding fails, start a new game
            }
        } catch {
            self.cloud.message = "Starting new game"
            print("Starting new game")
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
            undosUsed: undosUsed,
            manual4sUsed: manual4sUsed
        )

        saveGameStateLocally(gameState: gameState)
        
        do {
            let data = try JSONEncoder().encode(gameState)
            let tempFileURL = FileManager.default.temporaryDirectory.appendingPathComponent("GameState.json")
            try data.write(to: tempFileURL)

            cloud.loading = true
            cloud.message = "Saving to cloud"
            
            privateDatabase.fetch(withRecordID: recordID) { (record, error) in
                DispatchQueue.main.async { // Ensure updates happen on the main thread
                    let recordToSave: CKRecord
                    if let existingRecord = record {
                        recordToSave = existingRecord
                    } else {
                        recordToSave = CKRecord(recordType: "GameState", recordID: self.recordID)
                    }

                    recordToSave["stateAsset"] = CKAsset(fileURL: tempFileURL)

                    self.privateDatabase.save(recordToSave) { (savedRecord, saveError) in
                        DispatchQueue.main.async { // Ensure updates happen on the main thread
                            if let saveError = saveError as? CKError, saveError.code == .serverRecordChanged {
                                self.cloud.message = "Resolving conflict"
                                print("Resolving conflict")
                                self.resolveCloudConflict(tempFileURL: tempFileURL)
                            } else if saveError != nil {
                                self.cloud.message = "Not saved to cloud"
                                print("Not saved to cloud: \(error?.localizedDescription ?? "empty error")")
                                self.saveGameStateLocally(gameState: gameState)
                            } else {
                                self.cloud.message = "Saved to cloud"
                                print("Saved to cloud")
                            }
                        }
                        
                        self.resetCloudMessage()
                    }
                }
                
                self.resetCloudMessage()
            }
            
        } catch {
            self.cloud.message = "Game encoding failed"
            print("Game encoding failed")
        }
        
    }

    private func resetCloudMessage() {
        DispatchQueue.main.async {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { // Ensure updates happen on the main thread
                self.cloud.loading = false
                self.cloud.message = ""
                print("")
            }
        }
    }
    
    private func resolveCloudConflict(tempFileURL: URL) {
        
        cloud.loading = true
        cloud.message = "Resolving cloud conflict"
        
        privateDatabase.fetch(withRecordID: recordID) { (latestRecord, fetchError) in
            DispatchQueue.main.async { // Ensure updates happen on the main thread
                guard let latestRecord = latestRecord, fetchError == nil else {
                    self.cloud.message = "Conflict resolution failed"
                    print("Conflict resolution failed: \(fetchError?.localizedDescription ?? "empty error")")
                    self.resetCloudMessage()
                    return
                }

                latestRecord["stateAsset"] = CKAsset(fileURL: tempFileURL)

                self.privateDatabase.save(latestRecord) { (savedRecord, saveError) in
                    DispatchQueue.main.async { // Ensure updates happen on the main thread
                        if saveError != nil {
                            self.cloud.message = "Conflict and cloud failed"
                            print("Conflict and cloud failed: \(saveError?.localizedDescription ?? "empty error")")
                        } else {
                            self.cloud.message = "Cloud and conflict resolved"
                            print("Cloud and conflict resolved")
                        }
                        
                        self.resetCloudMessage()
                    }
                }
            }
            
            self.resetCloudMessage()
        }
    }

    func saveGameStateLocally(gameState: GameState) {
        stopTimer() // Stop the timer when saving the game state

        if let data = try? JSONEncoder().encode(gameState) {
            do {
                try data.write(to: gameStateFileURL, options: .atomic)
                self.cloud.message = "Local save ok"
                print("Local save ok")
            } catch {
                self.cloud.message = "Local save failed"
                print("Local save failed")
            }
        }
    }

}


