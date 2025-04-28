//
//  ColorThemePresets.swift
//  Speed2048
//
//  Created by Lucas Longo on 4/27/25.
//

import SwiftUI

struct ColorThemePresets: View {
    @EnvironmentObject var gameManager: GameManager
    
    // Define color theme pairs (background, font)
    let colorThemes: [(String, Color, Color)] = [
        ("Classic", Color.white.opacity(0.8), .black),
        ("Dark Mode", Color.black.opacity(0.8), .white),
        ("Ocean", Color.blue.opacity(0.2), Color(red: 0, green: 0, blue: 0.5)),
        ("Forest", Color(red: 0.2, green: 0.5, blue: 0.2).opacity(0.2), Color(red: 0, green: 0.3, blue: 0)),
        ("Warm", Color(red: 1.0, green: 0.9, blue: 0.8).opacity(0.8), Color(red: 0.6, green: 0.3, blue: 0)),
        ("Lavender", Color(red: 0.8, green: 0.7, blue: 1.0).opacity(0.3), Color(red: 0.4, green: 0, blue: 0.6)),
        ("Sunset", Color(red: 1.0, green: 0.8, blue: 0.6).opacity(0.3), Color(red: 0.8, green: 0.4, blue: 0)),
        ("Cool Breeze", Color(red: 0.6, green: 0.8, blue: 1.0).opacity(0.3), Color(red: 0, green: 0.4, blue: 0.8)),
        ("Earthy", Color(red: 0.8, green: 0.7, blue: 0.5).opacity(0.3), Color(red: 0.5, green: 0.4, blue: 0)),
        ("Pastel", Color(red: 1.0, green: 0.8, blue: 0.9).opacity(0.3), Color(red: 0.8, green: 0.4, blue: 0.6)),
        ("Neon", Color(red: 1.0, green: 1.0, blue: 0.2).opacity(0.3), Color(red: 1.0, green: 0, blue: 1.0)),
        ("Retro", Color(red: 0.8, green: 0.5, blue: 0.2).opacity(0.3), Color(red: 0.5, green: 0.1, blue: 0.3)),
        ("Cyberpunk", Color(red: 0.2, green: 0.1, blue: 0.5).opacity(0.3), Color(red: 0.8, green: 0.2, blue: 1.0)),
        ("Monochrome", Color.gray.opacity(0.3), Color.black)
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Color Themes")
                .font(.headline)
                .padding(.bottom, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(colorThemes, id: \.0) { theme in
                        ThemeButton(
                            name: theme.0,
                            background: theme.1,
                            foreground: theme.2
                        )
                        .onTapGesture {
                            gameManager.backgroundColor = theme.1
                            gameManager.fontColor = theme.2
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

struct ThemeButton: View {
    let name: String
    let background: Color
    let foreground: Color
    
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(background)
                    .frame(width: 60, height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
                
                Text("Aa")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(foreground)
            }
            
            Text(name)
                .font(.caption)
                .foregroundStyle(.primary)
        }
    }
}
