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
    let maxWidth: CGFloat
    let fontSize: CGFloat
    let fontColor: Color
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: fontSize, weight: .bold))
            .padding()
            .frame(minWidth: minWidth, maxWidth: maxWidth, maxHeight: maxHeight)
            .background(gradient)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 4)
            .foregroundStyle(fontColor)
            .buttonStyle(BorderlessButtonStyle())
    }
}
