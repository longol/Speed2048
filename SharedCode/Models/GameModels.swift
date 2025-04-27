import Foundation

struct GameState: Codable, Equatable {
    var tiles: [Tile]
    var seconds: Int
    var undoStack: [[Tile]]
    var gameLevel: GameLevel
    var fastAnimations: Bool
    var undosUsed: Int
    var manual4sUsed: Int
    var boardSize: Int
    var deletedTilesCount: Int
    var backgroundColorRed: Double = 0.0
    var backgroundColorGreen: Double = 0.0
    var backgroundColorBlue: Double = 0.5
    var backgroundColorOpacity: Double = 0.2
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

enum GameAnimationState {
    case idle
    case animatingMove
    case animatingMerge
}

enum GameLevel: String, Codable, CaseIterable {
    case onlyTwos
    case regular
    case easy
    case onlyFours
    
    var description: String {
        switch self {
        case .onlyTwos:
            return "2s"
        case .regular:
            return "More 2s"
        case .easy:
            return "More 4s"
        case .onlyFours:
            return "4s"
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
    
    var nextTileValue: Int {
        switch self {
        case .onlyTwos: return 2
        default: return 4
        }
    }
}
