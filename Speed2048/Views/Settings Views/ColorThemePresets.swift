//
//  ColorThemePresets.swift
//  Speed2048
//
//  Created by Lucas Longo on 4/27/25.
//

import SwiftUI

struct ColorThemePresets: View {
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Color Themes")
                .font(.headline)
                .padding(.bottom, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ColorThemes.allCases, id: \.self) { theme in
                        ThemeButton(
                            name: theme.rawValue,
                            background: theme.backgroundColor,
                            foreground: theme.foregroundColor,
                            isSelected: isThemeSelected(theme)

                        )
                        .onTapGesture {
                            gameManager.backgroundColor = theme.backgroundColor
                            gameManager.fontColor = theme.foregroundColor
                            gameManager.selectedThemeName = theme.rawValue
                            gameManager.baseButtonColor = theme.buttonBaseColor
                        }
                        
                        
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    private func isThemeSelected(_ theme: ColorThemes) -> Bool {
        if !gameManager.selectedThemeName.isEmpty {
            return theme.rawValue == gameManager.selectedThemeName
        }
        // Fallback to color comparison if theme name isn't stored
        return gameManager.backgroundColor == theme.backgroundColor && gameManager.fontColor == theme.foregroundColor && gameManager.baseButtonColor == theme.buttonBaseColor
    }
}

struct ThemeButton: View {
    let name: String
    let background: Color
    let foreground: Color
    let isSelected: Bool

    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(background)
                    .frame(width: 60, height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.blue : Color.gray.opacity(0.5),
                                   lineWidth: isSelected ? 2 : 1)
                    )
                
                Text("Aa")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(foreground)
                    .underline(isSelected)
            }
            
            Text(name)
                .font(.caption)
                .foregroundStyle(.primary)
                .fontWeight(isSelected ? .bold : .regular)
                .underline(isSelected)
        }
        .frame(width: 60)
    }
}
