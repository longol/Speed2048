import SwiftUI
#if os(macOS)
import AppKit
#endif

// MARK: - Views

/// The main game view.
struct ContentView: View {
    @EnvironmentObject var gameManager: GameManager
    
    @State private var showSettings: Bool = false
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            
            headerView
            keyboardShortcuts
            
            ContentSliderView()
            Spacer()
            OverlayMessageView()
            Spacer()
            GameButtonsView()
            GameBoardView()

        }
#if os(macOS)
        .frame(minWidth: 400, minHeight: 750)
#endif
        .dynamicTypeSize(.xSmall ... .xxxLarge)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onDisappear {
            Task {
                await gameManager.saveGameState()
            }
        }
        .background(gameManager.backgroundColor)
        .foregroundStyle(gameManager.fontColor)
    }
    
    @ViewBuilder private var headerView: some View {
        HStack {
            Text("Speed 2048")
                .font(.largeTitle)
                .bold()
            
            Spacer()
            
            settingsButton
        }
        .padding()
        .alert(isPresented: $gameManager.showVersionChoiceAlert) {
            Alert(
                title: Text("Cloud Game Found"),
                message: Text("Cloud game with higher score found. Use it or use your local version?"),
                primaryButton: .default(Text("Use Cloud")) {
                    gameManager.applyVersionChoice(useCloud: true)
                },
                secondaryButton: .destructive(Text("Use Local")) {
                    gameManager.applyVersionChoice(useCloud: false)
                }
            )
        }
    }
    
    @ViewBuilder private var settingsButton: some View {
        Button {
            showSettings.toggle()
            gameManager.stopTimer()
        } label: {
            Image(systemName: "gear")
        }
        .keyboardShortcut(",", modifiers: [.command])
    }
    
    @ViewBuilder private var keyboardShortcuts: some View {
        Group {
            Button("") {
                Task {
                    await gameManager.saveGameState()
                }
            }
            .keyboardShortcut("s", modifiers: .command)
            
            Button("") {
                Task {
                    await gameManager.checkCloudVersion()
                }
            }
            .keyboardShortcut("o", modifiers: .command)
            Button("") {
                Task {
                    await gameManager.loadGameStateLocally()
                }
            }
            .keyboardShortcut("l", modifiers: [.command])
        }
        .frame(width: 0, height: 0)
        .hidden()
    }
    
}

