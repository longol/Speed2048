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
    
    func colorForValue(baseColor: Color) -> Color {
        // Get base color components
        let (baseR, baseG, baseB, _) = baseColor.components
        
        // Compute which "step" we're on (2, 4, 8, 16... etc)
        let exponent = log2(Double(self))
        
        // For lowest values (2, 4), stay very close to base color
        if exponent <= 2 {
            // Convert RGB components to HSB for base color
            var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
            #if canImport(UIKit)
            UIColor(red: CGFloat(baseR), green: CGFloat(baseG), blue: CGFloat(baseB), alpha: 1.0).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
            #elseif canImport(AppKit)
            NSColor(red: CGFloat(baseR), green: CGFloat(baseG), blue: CGFloat(baseB), alpha: 1.0).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
            #endif
            
            // Slightly adjust saturation and brightness for visual distinction
            let satAdjust = 0.1 * exponent
            let brightAdjust = 0.05 * exponent
            
            return Color(hue: Double(hue), 
                         saturation: Swift.min(1.0, Double(saturation) + satAdjust),
                         brightness: Swift.max(0.5, Double(brightness) - brightAdjust))
        }
        
        // For higher values, gradually change color
        // Define how many steps until we reach maximum saturation
        let stepsPerCycle: Double = 24
        
        // Gradually shift hue based on value
        let hueShift = (exponent - 2) / stepsPerCycle * 0.5 // More gradual shift
        let hue = (baseR + baseG + baseB) / 3.0 + hueShift
        
        // Increase saturation and adjust brightness as value grows
        let saturation = Swift.min(1.0, 0.5 + exponent * 0.025)
        let brightness = Swift.max(0.5, 1.0 - exponent * 0.03)
        
        return Color(hue: hue.truncatingRemainder(dividingBy: 1.0),
                    saturation: saturation,
                    brightness: brightness)
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
        // Convert to RGB color space first
        guard let rgbColor = nsColor.usingColorSpace(.sRGB) else {
            // Fallback if conversion fails
            return (0, 0, 0, 1)
        }
        
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        rgbColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b), Double(a))
    }
}
#endif

extension View {
    
    func themeAwareButtonStyle(
        themeBackground: Color,
        themeFontColor: Color,
        uiSize: UISizes = .small,
        maxHeight: CGFloat = 0,
        minWidth: CGFloat = 0,
        maxWidth: CGFloat = 10000,
    ) -> some View {

        // Create complementary colors based on the theme background
        let (r, g, b, a) = themeBackground.components
        
        // Create a slightly darker variant for gradient
        let darkerVariant = Color(
            red: max(0, r - 0.2),
            green: max(0, g - 0.2),
            blue: max(0, b - 0.2),
            opacity: min(1.0, a + 0.3)
        )
        
        // Create a slightly lighter variant for gradient
        let lighterVariant = Color.white.opacity(0.3)
        
        let gradient = LinearGradient(
            gradient: Gradient(colors: [lighterVariant, darkerVariant]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        
        return self.modifier(
            GameButtonModifier(
                gradient: gradient,
                maxHeight: maxHeight > 0 ? maxHeight : uiSize.maxHeight,
                minWidth: minWidth > 0 ? minWidth : uiSize.minWidth,
                maxWidth: maxWidth,
                fontSize: uiSize.fontSize,
                fontColor: themeFontColor
            )
        )
    }
    
}
