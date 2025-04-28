//
//  ViewModifiers.swift
//  Speed2048
//
//  Created by Lucas Longo on 4/2/25.
//

import SwiftUI

struct GameButtonModifier: ViewModifier {
    let gradient: LinearGradient
    let maxHeight: CGFloat
    let minWidth: CGFloat
    let fontSize: CGFloat
    let fontColor: Color
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: fontSize, weight: .bold))
            .padding()
            .frame(minWidth: minWidth, maxHeight: maxHeight)
            .background(gradient)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 4)
            .foregroundStyle(fontColor)
            .buttonStyle(BorderlessButtonStyle())
    }
}

struct BorderedButtonModifier: ViewModifier {
    let backgroundColor: Color
    let borderColor: Color
    let borderWidth: CGFloat
    let maxHeight: CGFloat
    let minWidth: CGFloat
    let fontSize: CGFloat
    let fontColor: Color
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: fontSize, weight: .semibold))
            .frame(minWidth: minWidth, maxHeight: maxHeight)
            .background(backgroundColor.opacity(0.8))
            .foregroundStyle(fontColor)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor.opacity(0.8), lineWidth: borderWidth)
            )
            .cornerRadius(8)
    }
}



extension View {
    
    func themeAwareButtonStyle(
        themeBackground: Color,
        themeFontColor: Color,
        uiSize: UISizes = .small
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
        let lighterVariant = Color(
            red: min(1.0, r + 0.1),
            green: min(1.0, g + 0.1),
            blue: min(1.0, b + 0.1),
            opacity: min(1.0, a + 0.3)
        )
        
        let gradient = LinearGradient(
            gradient: Gradient(colors: [lighterVariant, darkerVariant]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Ensure font color has good contrast with button background
        let buttonFontColor = themeFontColor
        
        return self.modifier(
            GameButtonModifier(
                gradient: gradient,
                maxHeight: uiSize.maxHeight,
                minWidth: uiSize.minWidth,
                fontSize: uiSize.fontSize,
                fontColor: buttonFontColor
            )
        )
    }

    
    func borderedButtonStyle(
        backgroundColor: Color = .white,
        borderColor: Color = .blue,
        borderWidth: CGFloat = 4,
        fontColor: Color = .blue,
        uiSize: UISizes = .small
    ) -> some View {
        self.modifier(
            BorderedButtonModifier(
                backgroundColor: backgroundColor,
                borderColor: borderColor,
                borderWidth: borderWidth,
                maxHeight: uiSize.maxHeight,
                minWidth: uiSize.minWidth,
                fontSize: uiSize.fontSize,
                fontColor: fontColor
            )
        )
    }

    
    func gameButtonStyle(firstColor: Color, secondColor: Color, fontColor: Color = .white, uiSize: UISizes = .small) -> some View {
        let gradient = LinearGradient(
            gradient: Gradient(colors: [firstColor, secondColor]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        return self.modifier(
            GameButtonModifier(
                gradient: gradient,
                maxHeight: uiSize.maxHeight,
                minWidth: uiSize.minWidth,
                fontSize: uiSize.fontSize,
                fontColor: fontColor
            )
        )
    }
    
    func gradientButtonStyle(gradient: LinearGradient, maxHeight: Double = 55, minWidth: CGFloat = 55, fontSize:CGFloat = 32, fontColor: Color = .white) -> some View {
        self.modifier(
            GameButtonModifier(
                gradient: gradient,
                maxHeight: maxHeight,
                minWidth: minWidth,
                fontSize: fontSize,
                fontColor: fontColor
            )
        )
    }
}

