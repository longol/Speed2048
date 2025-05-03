import SwiftUI
#if os(macOS)
import AppKit
#endif

class BoardLogic {
    let boardSize: Int
    
    init(boardSize: Int = 4) {
        self.boardSize = boardSize
    }
    
    // Get all empty positions on the board
    func getEmptyPositions(tiles: [Tile]) -> [(row: Int, col: Int)] {
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
    
    // Calculate all movements and merges for a given direction
    func calculateMoves(tiles: [Tile], direction: Direction) -> (
        targetPositions: [UUID: (row: Int, col: Int)], 
        mergeInstructions: [MergeInstruction], 
        moved: Bool
    ) {
        var allMergeInstructions: [MergeInstruction] = []
        var allTargetPositions: [UUID: (row: Int, col: Int)] = [:]
        var overallMoved = false
        
        let isHorizontal = (direction == .left || direction == .right)
        let ascending = (direction == .left || direction == .up)
        
        for lineIndex in 0..<boardSize {
            let lineTiles = tiles.filter { isHorizontal ? $0.row == lineIndex : $0.col == lineIndex }
            
            let lineResult = processLine(
                lineTiles: lineTiles,
                lineIndex: lineIndex,
                isHorizontal: isHorizontal,
                ascending: ascending
            )
            
            allTargetPositions.merge(lineResult.targetPositions) { (_, new) in new }
            allMergeInstructions.append(contentsOf: lineResult.mergeInstructions)
            if lineResult.movedInLine {
                overallMoved = true
            }
        }
        
        return (allTargetPositions, allMergeInstructions, overallMoved)
    }
    
    // Process a single line (row or column) for movement
    private func processLine(
        lineTiles: [Tile],
        lineIndex: Int,
        isHorizontal: Bool,
        ascending: Bool
    ) -> (targetPositions: [UUID: (row: Int, col: Int)], mergeInstructions: [MergeInstruction], movedInLine: Bool) {
        
        var targetPositions: [UUID: (row: Int, col: Int)] = [:]
        var mergeInstructions: [MergeInstruction] = []
        var movedInLine = false
        
        guard !lineTiles.isEmpty else {
            return (targetPositions, mergeInstructions, movedInLine)
        }

        // Sort tiles based on direction
        let sortedTiles = lineTiles.sorted {
            if ascending {
                return isHorizontal ? $0.col < $1.col : $0.row < $1.row
            } else {
                return isHorizontal ? $0.col > $1.col : $0.row > $1.row
            }
        }

        let targetStart = ascending ? 0 : boardSize - 1
        let targetStep = ascending ? 1 : -1
        var currentTargetPos = targetStart
        var i = 0

        while i < sortedTiles.count {
            let currentTile = sortedTiles[i]
            let targetRow = isHorizontal ? lineIndex : currentTargetPos
            let targetCol = isHorizontal ? currentTargetPos : lineIndex
            let currentPos = (row: currentTile.row, col: currentTile.col)
            let targetPos = (row: targetRow, col: targetCol)

            // Check for merge with the next tile
            if i < sortedTiles.count - 1, currentTile.value == sortedTiles[i+1].value {
                let nextTile = sortedTiles[i+1]
                let newValue = currentTile.value * 2
                
                targetPositions[currentTile.id] = targetPos
                targetPositions[nextTile.id] = targetPos
                
                // Check if either tile actually moved or if a merge happened
                if currentPos != targetPos || (nextTile.row == targetRow && nextTile.col == targetCol) == false {
                    movedInLine = true
                }

                mergeInstructions.append(MergeInstruction(mainTileID: currentTile.id,
                                                          mergingTileID: nextTile.id,
                                                          newValue: newValue))
                i += 2 // Skip next tile as it's merged
            } else {
                // No merge, just slide
                targetPositions[currentTile.id] = targetPos
                if currentPos != targetPos {
                    movedInLine = true
                }
                i += 1
            }
            currentTargetPos += targetStep
        }
        
        return (targetPositions, mergeInstructions, movedInLine)
    }
    
    func generatePerfectBoard() -> [Tile] {
        return [
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
    }
}


/// Simple key identifiers.
