//
//  GameButtonsView.swift
//  Speed2048
//
//  Created by Lucas Longo on 5/3/25.
//

import SwiftUI

struct GameButtonsView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var showAlert = false
    @State private var undoTimer: Timer?
    let frameHeight: CGFloat = 50
    
    var body: some View {
            HStack {
                Spacer()
                undoButton
                addFourButton
                Spacer()
                editButton
                newButton
                Spacer()
            }
            .padding(.horizontal, 10)
    }
    
    @ViewBuilder private var newButton: some View {
        Button(action: {
            showAlert = true
            gameManager.stopTimer()
        }) {
            Image(systemName: "plus.circle")
        }
        .keyboardShortcut("n", modifiers: [.command])
        .themeAwareButtonStyle(
            themeBackground: gameManager.baseButtonColor,
            themeFontColor: gameManager.fontColor,
            uiSize: gameManager.uiSize
        )
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Start New Game"),
                message: Text("Are you sure you want to start a new game?"),
                primaryButton: .default(
                    Text("Cancel"),
                    action: gameManager.startTimer
                ),
                secondaryButton: .destructive(
                    Text("New Game"),
                    action: gameManager.newGame
                )
            )
        }
        .onChange(of: showAlert, { oldValue, newValue in
            if !newValue {
                gameManager.startTimer() // Restart the timer when the alert is dismissed
            }
        })
    }
    
    @ViewBuilder private var undoButton: some View {
        Button(action: { gameManager.undo() }) {
            Image(systemName: "arrow.uturn.backward.circle")
        }
        .onLongPressGesture(
            minimumDuration: 0.1, // Adjust the duration for responsiveness
            pressing: { isPressing in
                if isPressing {
                    startUndoTimer()
                } else {
                    stopUndoTimer()
                }
            },
            perform: {}
        )
        .themeAwareButtonStyle(
            themeBackground: gameManager.baseButtonColor,
            themeFontColor: gameManager.fontColor,
            uiSize: gameManager.uiSize
        )
        .keyboardShortcut("z", modifiers: [.command])
        
    }
    
    @ViewBuilder private var addFourButton: some View {
        Button(action: { gameManager.forceTile() }) {
            Image(systemName: gameManager.gameLevel == .onlyTwos ? "2.circle" :  "4.circle")
        }
        .themeAwareButtonStyle(
            themeBackground: gameManager.baseButtonColor,
            themeFontColor: gameManager.fontColor,
            uiSize: gameManager.uiSize
        )
        .keyboardShortcut("4", modifiers: [.command])
        .keyboardShortcut("2", modifiers: [.command])
    }
    
    @ViewBuilder private var editButton: some View {
        Button(action: { gameManager.toggleEditMode() }) {
            Image(systemName: gameManager.isEditMode ? "pencil.slash" : "pencil")
        }
        .themeAwareButtonStyle(
            themeBackground: gameManager.isEditMode ? Color.red.opacity(0.7) : gameManager.baseButtonColor,
            themeFontColor: gameManager.fontColor,
            uiSize: gameManager.uiSize
        )
        .keyboardShortcut("e", modifiers: [.command])
    }
    
    
    
    private func startUndoTimer() {
        stopUndoTimer() // Ensure no existing timer is running
        undoTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                gameManager.undo()
            }
        }
    }
    
    private func stopUndoTimer() {
        undoTimer?.invalidate()
        undoTimer = nil
    }

}
