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
        
        // 1) Compute which “step” we’re on
        let exponent = log2(Double(self))
        
    // 2) Define how many steps until we sweep the full hue range.
        //    (e.g. 12 steps = one full cycle around the color wheel)
        let stepsPerCycle: Double = 24
        
        // 3) Compute hue in [0,1], wrapping around if exponent > stepsPerCycle
        let hue = (exponent / stepsPerCycle).truncatingRemainder(dividingBy: 1.0)
        
        // 4) Optionally scale saturation & brightness so larger tiles look “hotter”
        let saturation = Swift.min(1.0, 0.5 + exponent * 0.03)
        let brightness = Swift.max(0.5, 1.0 - exponent * 0.04)
        
        return Color(hue: hue, saturation: saturation, brightness: brightness)
    }



}


extension Double {
    func percentage(_ decimalPlaces: Int) -> String {
        return String(format: "%.\(decimalPlaces)f", self * 100) + "%"
    }
}



#if canImport(UIKit)
import UIKit
extension Color {
    var components: (red: Double, green: Double, blue: Double, opacity: Double) {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b), Double(a))
    }
}
#elseif canImport(AppKit)
import AppKit
extension Color {
    var components: (red: Double, green: Double, blue: Double, opacity: Double) {
        let nsColor = NSColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        nsColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b), Double(a))
    }
}
#endif
