//
//  Enums.swift
//  Speed2048
//
//  Created by Lucas Longo on 4/28/25.
//

import Foundation
import SwiftUI

enum AnimationLevel: String, CaseIterable {
    case smooth = "Smooth"
    case fast = "Fast"
}

enum Direction {
    case up, down, left, right
}

enum GameAnimationState {
    case idle
    case animatingMove
    case animatingMerge
}

enum UISizes: String, Codable, CaseIterable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    
    var minWidth: CGFloat {
        switch self {
        case .small: return 40
        case .medium: return 60
        case .large: return 80
        }
    }
    var maxHeight: CGFloat {
        switch self {
        case .small: return 40
        case .medium: return 60
        case .large: return 80
        }
    }
    var fontSize: CGFloat {
        switch self {
        case .small: return 16
        case .medium: return 20
        case .large: return 24
        }
    }
}


enum GameDataManagementError: Error {
    case decodingError
    case cloudKitError
    case cloudUserNotSetup
    case noGameFound
    case localSaveFailure
    
    var localizedDescription: String {
        switch self {
        case .decodingError:
            return "decodingError"
        case .cloudKitError:
            return "cloudKitError"
        case .cloudUserNotSetup:
            return "cloudUserNotSetup"
        case .noGameFound:
            return "noGameFound"
        case .localSaveFailure:
            return "localSaveFailure"
        }
    }
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

enum ColorThemes: String, CaseIterable {
    case classic = "Classic"
    case dark = "Dark"
    case ocean = "Ocean"
    case forest = "Forest"
    case warm = "Warm"
    case lavender = "Lavender"
    case sunset = "Sunset"
    case cool = "Cool"
    case earthy = "Earthy"
    case pastel = "Pastel"
    case neon = "Neon"
    case retro = "Retro"
    case cyberpunk = "Cyberpunk"
    case monochrome = "Monochrome"
    
    var backgroundColor: Color {
        switch self {
        case .classic:
            return Color.white.opacity(0.8)
        case .dark:
            return Color.black.opacity(0.8)
        case .ocean:
            return Color.blue.opacity(0.2)
        case .forest:
            return Color(red: 0.2, green: 0.5, blue: 0.2).opacity(0.2)
        case .warm:
            return Color(red: 1.0, green: 0.9, blue: 0.8).opacity(0.8)
        case .lavender:
            return Color(red: 0.8, green: 0.7, blue: 1.0).opacity(0.3)
        case .sunset:
            return Color(red: 1.0, green: 0.8, blue: 0.6).opacity(0.3)
        case .cool:
            return Color(red: 0.6, green: 0.8, blue: 1.0).opacity(0.3)
        case .earthy:
            return Color(red: 0.8, green: 0.7, blue: 0.5).opacity(0.3)
        case .pastel:
            return Color(red: 1.0, green: 0.8, blue: 0.9).opacity(0.3)
        case .neon:
            return Color(red: 1.0, green: 1.0, blue: 0.2).opacity(0.3)
        case .retro:
            return Color(red: 0.8, green: 0.5, blue: 0.2).opacity(0.3)
        case .cyberpunk:
            return Color(red: 0.2, green: 0.1, blue: 0.5).opacity(0.3)
        case .monochrome:
            return Color.gray.opacity(0.3)
        }
    }
    
    var foregroundColor: Color {
        switch self {
        case .classic:
            return .black
        case .dark:
            return .white
        case .ocean:
            return Color(red: 0, green: 0, blue: 0.5)
        case .forest:
            return Color(red: 0, green: 0.3, blue: 0)
        case .warm:
            return Color(red: 0.6, green: 0.3, blue: 0)
        case .lavender:
            return Color(red: 0.4, green: 0, blue: 0.6)
        case .sunset:
            return Color(red: 0.8, green: 0.4, blue: 0)
        case .cool:
            return Color(red: 0, green: 0.4, blue: 0.8)
        case .earthy:
            return Color(red: 0.5, green: 0.4, blue: 0)
        case .pastel:
            return Color(red: 0.8, green: 0.4, blue: 0.6)
        case .neon:
            return Color(red: 1.0, green: 0, blue: 1.0)
        case .retro:
            return Color(red: 0.5, green: 0.1, blue: 0.3)
        case .cyberpunk:
            return Color(red: 0.8, green: 0.2, blue: 1.0)
        case .monochrome:
            return Color.black
        }
    }
    
    var buttonBaseColor: Color {
        switch self {
        case .classic:
            return Color.white.opacity(0.8)
        case .dark:
            return Color.black.opacity(0.8)
        case .ocean:
            return Color.blue.opacity(0.2)
        case .forest:
            return Color(red: 0.2, green: 0.5, blue: 0.2).opacity(0.2)
        case .warm:
            return Color(red: 1.0, green: 0.9, blue: 0.8).opacity(0.8)
        case .lavender:
            return Color(red: 0.8, green: 0.7, blue: 1.0).opacity(0.3)
        case .sunset:
            return Color(red: 1.0, green: 0.8, blue: 0.6).opacity(0.3)
        case .cool:
            return Color(red: 0.6, green: 0.8, blue: 1.0).opacity(0.3)
        case .earthy:
            return Color(red: 0.8, green: 0.7, blue: 0.5).opacity(0.3)
        case .pastel:
            return Color(red: 1.0, green: 0.8, blue: 0.9).opacity(0.3)
        case .neon:
            return Color(red: 1.0, green: 1.0, blue: 0.2).opacity(0.3)
        case .retro:
            return Color(red: 0.8, green: 0.5, blue: 0.2).opacity(0.3)
        case .cyberpunk:
            return Color(red: 0.2, green: 0.1, blue: 0.5).opacity(0.3)
        case .monochrome:
            return Color.gray.opacity(0.3)
        }
    }
}
