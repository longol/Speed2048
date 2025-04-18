import Foundation
import SwiftUI

extension Int {
    var formattedAsTime: String {
        let secondsInDay = 86400 // 3600 * 24
        let secondsInHour = 3600
        
        let days = self / secondsInDay
        let hours = (self % secondsInDay) / secondsInHour
        let minutes = (self % secondsInHour) / 60
        let seconds = self % 60

        var components: [String] = []
        if days > 0 { components.append("\(days) d") }
        if hours > 0 { components.append("\(hours) h") }
        if minutes > 0 { components.append("\(minutes) m") }
        // Always show seconds unless days, hours, or minutes are present and seconds are 0
        if !(days > 0 || hours > 0 || minutes > 0) || seconds > 0 {
             components.append("\(seconds) s")
        }

        return components.joined(separator: " ")
    }
    
    var colorForValue: Color {
        switch self {
        case 2: return Color(red: 0.90, green: 0.80, blue: 0.70)
        case 4: return Color(red: 0.75, green: 0.65, blue: 0.55)
        case 8: return Color(red: 0.95, green: 0.69, blue: 0.47)
        case 16: return Color(red: 0.96, green: 0.58, blue: 0.39)
        case 32: return Color(red: 0.96, green: 0.48, blue: 0.37)
        case 64: return Color(red: 0.96, green: 0.37, blue: 0.23)
        case 128: return Color(red: 0.93, green: 0.81, blue: 0.45)
        case 256: return Color(red: 0.93, green: 0.80, blue: 0.38)
        case 512: return Color(red: 0.93, green: 0.79, blue: 0.31)
        case 1024: return Color(red: 0.93, green: 0.78, blue: 0.24)
        case 2048: return Color(red: 0.93, green: 0.77, blue: 0.17)
        case 4096: return Color(red: 0.80, green: 0.65, blue: 0.00)
        case 8192: return Color(red: 0.70, green: 0.55, blue: 0.00)
        case 16384: return Color(red: 0.60, green: 0.45, blue: 0.00)
        case 32768: return Color(red: 0.50, green: 0.35, blue: 0.00)
        case 65536: return Color(red: 0.40, green: 0.30, blue: 0.00)
        case 131072: return Color(red: 0.30, green: 0.25, blue: 0.00)
        default: return Color(red: 0.20, green: 0.20, blue: 0.20)
        }
    }
}


extension Double {
    func percentage(_ decimalPlaces: Int) -> String {
        return String(format: "%.\(decimalPlaces)f", self * 100) + "%"
    }
}



