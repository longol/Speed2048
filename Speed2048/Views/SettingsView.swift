import SwiftUI

enum AnimationLevel: String, CaseIterable {
    case smooth = "Smooth"
    case fast = "Fast"
}

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var gameManager: GameManager
    
    var body: some View {
        ScrollView {
            
            header
            
            Divider()
            
            GameLevelPicker(gameManager: gameManager)
            
            Divider()
            
            BoardSizePicker(gameManager: gameManager)
            
            Divider()
            
            EscalatingModeToggle(gameManager: gameManager)
            
            Divider()

            perfectBoardView

            Divider()
            
            AnimationSpeedToggle(gameManager: gameManager)
            
            Divider()
            
            cloudSyncSection
            
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
                gameManager.startTimer()
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
            }
            .padding(5)
        }
    }
    
//    @ViewBuilder private var gameLevelPicker: some View {
//        VStack(alignment: .leading) {
//            
//            Text("Game Level").bold()
//            
//            Picker("Game Level", selection: $gameManager.gameLevel) {
//                ForEach(GameLevel.allCases, id: \.self) { level in
//                    Text(level.description).tag(level)
//                }
//            }
//#if os(watchOS)
//            .pickerStyle(InlinePickerStyle())
//#else
//            .pickerStyle(SegmentedPickerStyle())
//#endif
//            
//            HStack {
//                Spacer()
//                Text(gameManager.gameLevel.penaltyString)
//                    .font(.caption)
//                Spacer()
//            }
//            
//            
//        }
//    }
    
//    @ViewBuilder private var boardSizePicker: some View {
//        VStack(alignment: .leading) {
//            Text("Board Size").bold()
//            
//            HStack {
//                Text("4x4")
//                Slider(value: Binding(
//                    get: { Double(gameManager.boardSize) },
//                    set: { gameManager.boardSize = Int($0) }
//                ), in: 4...10, step: 1)
//                Text("10x10")
//            }
//            
//            HStack {
//                Spacer()
//                Text("\(gameManager.boardSize)x\(gameManager.boardSize)")
//                    .font(.headline)
//                Spacer()
//            }
//            
//            HStack {
//                Spacer()
//                Text("Changing board size will start a new game")
//                    .font(.caption)
//                    .foregroundColor(.gray)
//                Spacer()
//            }
//        }
//    }
    
//    @ViewBuilder private var escalatingModeToggle: some View {
//        VStack(alignment: .leading) {
//            Text("Game Modes").bold()
//            
//            Toggle(isOn: $gameManager.escalatingMode) {
//                Label("Escalating Tiles", systemImage: "arrow.up.forward")
//            }
//            .padding()
//            
//            Text("In escalating mode, when no more 2s remain, you'll start getting 4s and 8s. When no more 4s remain, you'll start getting 8s and 16s, and so on.")
//                .font(.caption)
//                .foregroundColor(.gray)
//                .padding(.horizontal)
//        }
//    }
    
//    @ViewBuilder private var animationSpeedToggle: some View {
//        VStack(alignment: .leading) {
//            Text("Animation Levels").bold()
//            Toggle(isOn: $gameManager.fastAnimations) {
//                Label("Fast animations?", systemImage: "hare")
//            }
//            .padding()
//        }
//    }
    
    @ViewBuilder private var cloudSyncSection: some View {
        VStack(alignment: .center) {
            HStack {
                Text("Cloud Sync").bold()
                Spacer()
            }
            HStack {
                
                Button {
                    Task {
                        await gameManager.saveGameState()
                    }
                } label: {
                    Label("Cloud Save", systemImage: "icloud.and.arrow.up")
                }
                .keyboardShortcut("s", modifiers: [.command])
                
                Button {
                    gameManager.applyVersionChoice(useCloud: true)
                } label: {
                    Label("Cloud Game ", systemImage: "icloud.and.arrow.down")
                }
                .keyboardShortcut("o", modifiers: [.command])
                
                Button {
                    Task {
                        await gameManager.loadGameStateLocally()
                    }
                } label: {
                    Label("Local Game", systemImage: "externaldrive")
                }
                .keyboardShortcut("l", modifiers: [.command])
                
            }
            .buttonStyle(.borderedProminent)
            .disabled(!gameManager.statusMessage.isEmpty)
            
            HStack {
                if !gameManager.statusMessage.isEmpty {
                    Label(gameManager.statusMessage, systemImage: "bolt.horizontal.icloud")
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
