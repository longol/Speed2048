import SwiftUI

enum AnimationLevel: String, CaseIterable {
    case smooth = "Smooth"
    case fast = "Fast"
}

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        ScrollView {
            
            header

            Divider()
            
            ColorThemePresets()
                .padding(.vertical)

            TileColorPreviewView()
                .padding(.bottom)

            Divider()
            
            buttonSizeView
            
            Divider()

            cloudSyncSection
            
            Divider()
            
            perfectBoardView
            
            Divider()
            
            contactView
        }
        .padding()
        .background(Color(gameManager.backgroundColor))
        .foregroundStyle(gameManager.fontColor)
    }
    
    @ViewBuilder private var header: some View {
        HStack {
            Text("Settings")
                .font(.largeTitle)
                .bold()
            Spacer()
            Button(action: {
                gameManager.startTimer()
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
            }
            .padding(5)
        }
    }
    
    @ViewBuilder private var buttonSizeView: some View {
        VStack(alignment: .center) {
            HStack {
                Text("Button Sizes").bold()
                Spacer()
            }
            
            Picker("Button Sizes", selection: $gameManager.uiSize) {
                ForEach(UISizes.allCases, id: \.self) { size in
                    Text(size.rawValue)
                        .tag(size)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    @ViewBuilder private var cloudSyncSection: some View {
        VStack(alignment: .center) {
            HStack {
                Text("Cloud Sync").bold()
                Spacer()
            }
            
#if os(macOS)
            HStack {
                cloudSyncButtons
            }
#else
            VStack {
                cloudSyncButtons
            }
#endif
            
            if gameManager.showOverlayMessage {
                HStack {
                    Label(gameManager.overlayMessage, systemImage: "bolt.horizontal.icloud")
                    ProgressView()
                        .scaleEffect(0.5)
                }
                .font(.caption)
                .foregroundStyle(.gray)
                .frame(height: 20)
            }

        }
    }
    
    @ViewBuilder private var cloudSyncButtons: some View {
        Group {
            Button {
                Task {
                    await gameManager.saveGameState()
                }
            } label: {
                Label("Save to Cloud", systemImage: "icloud.and.arrow.up")
            }
            .keyboardShortcut("s", modifiers: [.command])
            
            Button {
                gameManager.applyVersionChoice(useCloud: true)
            } label: {
                Label("Get Cloud Game ", systemImage: "icloud.and.arrow.down")
            }
            .keyboardShortcut("o", modifiers: [.command])
            
            Button {
                Task {
                    await gameManager.loadGameStateLocally()
                }
            } label: {
                Label("Load Local Game", systemImage: "externaldrive")
            }
            .keyboardShortcut("l", modifiers: [.command])
        }
        .themeAwareButtonStyle(
            themeBackground: gameManager.isEditMode ? Color.red.opacity(0.7) : gameManager.backgroundColor,
            themeFontColor: gameManager.fontColor,
            uiSize: gameManager.uiSize
        )
    }

    
    @ViewBuilder private var perfectBoardView: some View {
        HStack {
            Text("Objective")
                .bold()
            Spacer()
        }
        HStack {
            Text("Is it possibel to reach 'The Perfect Board'?")
                .italic()
            Spacer()
        }
        
        // Add image called PerfectBoard and make it fit in the view
        Image("PerfectBoard")
            .resizable()
            .scaledToFit()
            .frame(width: 200, height: 200)    
    }
    
    @ViewBuilder private var contactView: some View {
        HStack {
            Text("Send us your feedback!")
                .bold()
            Spacer()
        }
        
        Link("Visit site", destination: URL(string: "https://lucaslongo.com/Speed2048/")!)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.blue)
            .foregroundStyle(.white)
            .cornerRadius(5)
    }
}
