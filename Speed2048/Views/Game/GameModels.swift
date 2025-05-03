import Foundation
import SwiftUI

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
    var uiSize: UISizes
    var selectedThemeName: String
    var backgroundColorRed: Double
    var backgroundColorGreen: Double
    var backgroundColorBlue: Double
    var backgroundColorOpacity: Double
    var fontColorRed: Double
    var fontColorGreen: Double
    var fontColorBlue: Double
    var fontColorOpacity: Double
    var baseButtonColorRed: Double
    var baseButtonColorGreen: Double
    var baseButtonColorBlue: Double
    var baseButtonColorOpacity: Double
    var selectedTab: Int
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


