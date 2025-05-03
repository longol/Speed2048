//
//  ContentSliderView.swift
//  Speed2048
//
//  Created by Lucas Longo on 5/3/25.
//

import SwiftUI

struct ContentSliderView: View {
    @EnvironmentObject var gameManager: GameManager
    let numViews: Int = 8
    
    var body: some View {
        VStack {
            
            HStack(alignment: .center) {

                leftIndexButton
                
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        Group {
                            GameLevelPicker()
                            BoardSizePicker()
                            AnimationSpeedToggle()
                            ColorPickerBackground()
                            ColorPickerFonts()
                            ColorPickerButtons()
                            GameStatsView()
                            GameCheatsView()
                        }
                        .frame(width: geo.size.width)
                    }
                    .offset(x: -CGFloat(gameManager.selectedTab) * geo.size.width)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: gameManager.selectedTab)
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                let horizontalAmount = value.translation.width
                                let pageWidth = geo.size.width / 2
                                
                                // Determine swipe direction and update tab if needed
                                if horizontalAmount > pageWidth && gameManager.selectedTab > 0 {
                                    gameManager.selectedTab -= 1
                                } else if horizontalAmount < -pageWidth && gameManager.selectedTab < numViews {
                                    gameManager.selectedTab += 1
                                }
                            }
                    )
                }
                .clipped()
                
                rightIndexButton
            }
            
            pageIndicatorsView
                .padding()
                .opacity(0.5)
        }
        .padding(.horizontal, 10)
    }
    
    
    @ViewBuilder private var leftIndexButton: some View {
        Button(action: {
            gameManager.selectedTab = gameManager.selectedTab > 0 ? gameManager.selectedTab - 1 : numViews - 1
        }) {
            Image(systemName: "chevron.left")
                .imageScale(.large)
                .contentShape(Rectangle())  // Make entire frame tappable
        }
        .buttonStyle(.plain)
        .zIndex(1) // Ensure button stays on top
    }

    @ViewBuilder private var rightIndexButton: some View {
        Button(action: {
            gameManager.selectedTab = gameManager.selectedTab < numViews - 1 ? gameManager.selectedTab + 1 : 0
        }) {
            Image(systemName: "chevron.right")
                .imageScale(.large)
                .contentShape(Rectangle())  // Make entire frame tappable
        }
        .buttonStyle(.plain)
        .zIndex(1) // Ensure button stays on top
    }

    @ViewBuilder private var pageIndicatorsView: some View {
        HStack(spacing: 10) {
            ForEach(0..<numViews, id:\.self) { index in
                Circle()
                    .fill(gameManager.selectedTab == index ? Color.red : Color.gray)
                    .frame(width: 8, height: 8)
                    .onTapGesture {
                        gameManager.selectedTab = index
                    }
            }
        }
    }
}
