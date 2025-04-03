//
//  Helpers.swift
//  Endless2048
//
//  Created by Lucas Longo on 3/20/25.
//

import Foundation

enum Direction {
    case up, down, left, right
}

struct MergeInstruction {
    let mainTileID: UUID
    let mergingTileID: UUID
    let newValue: Int
}

struct GameState: Codable {
    let tiles: [Tile]
    let seconds: Int
    let undoStack: [[Tile]]
    let gameLevel: GameLevel
    let animationDurationSlide: Double
    let animationDurationShowHide: Double
    let boardSize: Int
    let tileDurations: [Int: [Int]]
    let lastTileTimestamps: [Int: Int]
}

struct TimingInfo: Codable {
    var lastTime: Int
    var secondToLastTime: Int
    var timeToBeat: Int
    var runningTime: Int = 0

    var trend: Trend {
        guard secondToLastTime > 0 else { return .neutral } // No trend if no second-to-last time
        return lastTime < secondToLastTime ? .up : .down
    }
}

enum Trend {
    case up
    case down
    case neutral
}

enum PenaltyType: String {
    case undoPenalty = "Undo"
    case addFourPenalty = "Four"
    case gameLevelPenalty = "Level"
    
    func amount(withLevel gameLevel: GameLevel) -> Int {
        var total = 0
        
        switch self {
        case .undoPenalty: total = 5
        case .addFourPenalty: total = 20
        default: break
        }
        
        return total + gameLevel.penaltyAmount
    }
}

enum GameLevel: String, Codable, CaseIterable {
    case onlyTwos = "Only 2s"
    case regular = "Regular"
    case easy = "Easy"
    case onlyFours = "Only 4s"
    
    var probabilityOfFours: Double {
        switch self {
        case .onlyTwos:
            return 0
        case .regular:
            return 0.25
        case .easy:
            return 0.75
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



