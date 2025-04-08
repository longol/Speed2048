//
//  ViewModifiers.swift
//  Quest131072
//
//  Created by Lucas Longo on 4/2/25.
//

import SwiftUI

struct GameButtonModifier: ViewModifier {
    let gradient: LinearGradient
    let maxHeight: CGFloat
    let minWidth: CGFloat
    let fontSize: CGFloat
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: fontSize, weight: .bold))
            .padding()
            .frame(minWidth: minWidth, maxHeight: maxHeight)
            .background(gradient)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 4)
            .foregroundColor(.white)
            .buttonStyle(BorderlessButtonStyle())
    }
}


extension View {
    func gameButtonStyle(gradient: LinearGradient, maxHeight: Double = 55, minWidth: CGFloat = 100, fontSize:CGFloat = 32,) -> some View {
        self.modifier(
            GameButtonModifier(
                gradient: gradient,
                maxHeight: maxHeight,
                minWidth: minWidth,
                fontSize: fontSize
            )
        )
    }
}

