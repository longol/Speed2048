import SwiftUI

enum AnimationLevel: String, CaseIterable {
    case smooth = "Smooth"
    case fast = "Fast"
}

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var gameModel: GameViewModel
    
    var body: some View {
        ScrollView {
            
            header
            
            Divider()
            
            gameLevelPicker
            
            Divider()

            perfectBoardView

            Divider()
            
            animationSpeedToggle
            
            Divider()
            
            cloudSyncSection // Added cloud sync section
            
            Divider()
            
            contactView
        }
        .padding()
    }
    
    @ViewBuilder private var header: some View {
        HStack {
            Text("Settings")
                .font(.largeTitle)
                .bold()
            Spacer()
            Button(action: {
                gameModel.startTimer()
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
            }
        }
    }
    
    @ViewBuilder private var gameLevelPicker: some View {
        VStack(alignment: .leading) {
            
            Text("Game Level").bold()
            
            Picker("Game Level", selection: $gameModel.gameLevel) {
                ForEach(GameLevel.allCases, id: \.self) { level in
                    Text(level.description).tag(level)
                }
            }
#if os(watchOS)
            .pickerStyle(InlinePickerStyle())
#else
            .pickerStyle(SegmentedPickerStyle())
#endif
            
            HStack {
                Spacer()
                Text(gameModel.gameLevel.penaltyString)
                    .font(.caption)
                Spacer()
            }
            
            
        }
    }
    
    @ViewBuilder private var animationSpeedToggle: some View {
        VStack(alignment: .leading) {
            Text("Animation Levels").bold()
            Toggle(isOn: $gameModel.fastAnimations) {
                Label("Fast animations?", systemImage: "hare")
            }
            .padding()
        }
    }
    
    @ViewBuilder private var cloudSyncSection: some View {
        VStack(alignment: .center) {
            HStack {
                Text("Cloud Sync").bold()
                Spacer()
            }
            HStack {
                
                Button {
                    gameModel.saveGameState()
                } label: {
                    Label("Save Game to Cloud", systemImage: "icloud.and.arrow.up")
                }
                .keyboardShortcut("s", modifiers: [.command])
                
                Button {
                    gameModel.applyVersionChoice(useCloud: true)
                } label: {
                    Label("Load Game from Cloud", systemImage: "icloud.and.arrow.down")
                }
                .keyboardShortcut("o", modifiers: [.command])
                
            }
            .buttonStyle(.borderedProminent)
            .disabled(!gameModel.statusMessage.isEmpty)
            
            HStack {
                if !gameModel.statusMessage.isEmpty {
                    Label(gameModel.statusMessage, systemImage: "bolt.horizontal.icloud")
                    ProgressView()
                        .scaleEffect(0.5)
                } else {
                    Text("Save or load your game progress using iCloud.")
                }
            }
            .font(.caption)
            .foregroundStyle(.gray)
            .frame(height: 20)
            
            
        }
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
            .foregroundColor(.white)
            .cornerRadius(5)
    }
}
