//
//  ViewModifiers.swift
//  TwentyFortyEight
//
//  Created by Lucas Longo on 2/17/25.
//

import SwiftUI

struct GameButtonModifier: ViewModifier {
    let gradient: LinearGradient
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .padding()
            .frame(minWidth: 100)
            .background(gradient)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 4)
            .foregroundColor(.white)
    }
}


extension View {
    func gameButtonStyle(gradient: LinearGradient) -> some View {
        self.modifier(GameButtonModifier(gradient: gradient))
    }
}

