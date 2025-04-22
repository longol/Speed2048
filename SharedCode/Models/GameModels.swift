import Foundation

struct GameState: Codable {
    var tiles: [Tile]
    var seconds: Int
    var undoStack: [[Tile]]
    var gameLevel: GameLevel
    var fastAnimations: Bool
    var undosUsed: Int
    var manual4sUsed: Int
    var boardSize: Int
    var escalatingMode: Bool
}

struct Tile: Codable, Identifiable, Equatable {
    let id: UUID
    var value: Int
    var row: Int
    var col: Int
}

struct MergeInstruction {
    let mainTileID: UUID
    let mergingTileID: UUID
    let newValue: Int
}

enum Direction {
    case up, down, left, right
}

enum GameLevel: String, Codable, CaseIterable {
    case onlyTwos
    case regular
    case easy
    case onlyFours
    
    var description: String {
        switch self {
        case .onlyTwos:
            return "Only 2s"
        case .regular:
            return "2s > 4s"
        case .easy:
            return "2s < 4s"
        case .onlyFours:
            return "Only 4s"
        }
    }
    
    var probabilityOfFours: Double {
        switch self {
        case .onlyTwos:
            return 0
        case .regular:
            return 0.10
        case .easy:
            return 0.90
        case .onlyFours:
            return 1
        }
    }
    
    var penaltyAmount: Int {
        switch self {
        case .onlyTwos: return -1
        case .regular: return 0
        case .easy: return 1
        case .onlyFours: return 2
        }
    }
    
    var penaltyString: String {
        switch self {
        case .onlyTwos: return "Gain a second!"
        case .regular: return "No penalty."
        case .easy: return "Loose 1 second."
        case .onlyFours: return "Loose 2 seconds!"
        }
    }

}
