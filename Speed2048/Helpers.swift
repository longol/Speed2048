//
//  Helpers.swift
//  Endless2048
//
//  Created by Lucas Longo on 3/20/25.
//

import SwiftUI
import Foundation
#if os(macOS)
import AppKit
#endif

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
    let cheatsUsed: Int
    let undosUsed: Int
    let manual4sUsed: Int
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

// MARK: - macOS Keyboard Handling
#if os(macOS)
/// A view that captures key events on macOS.
struct KeyEventHandlingView: NSViewRepresentable {
    var keyDownHandler: (Key) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = KeyView()
        view.keyDownHandler = keyDownHandler
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    class KeyView: NSView {
        var keyDownHandler: ((Key) -> Void)?

        override var acceptsFirstResponder: Bool { true }

        override func keyDown(with event: NSEvent) {
            // Arrow key keyCodes: left=123, right=124, down=125, up=126.
            switch event.keyCode {
            case 123:
                keyDownHandler?(.left)
            case 124:
                keyDownHandler?(.right)
            case 125:
                keyDownHandler?(.down)
            case 126:
                keyDownHandler?(.up)
            default:
                break
            }
        }
        
        override func viewDidMoveToWindow() {
            window?.makeFirstResponder(self)
        }
    }
}

/// Simple key identifiers.
enum Key {
    case left, right, up, down
}
#else
// For non-macOS platforms, just provide an empty view.
struct KeyEventHandlingView: View {
    var keyDownHandler: (Key) -> Void
    var body: some View { EmptyView() }
}
enum Key { case left, right, up, down }
#endif


