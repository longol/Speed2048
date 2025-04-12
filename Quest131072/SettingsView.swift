import SwiftUI

enum AnimationLevel: String, CaseIterable {
    case smooth = "Smooth"
    case fast = "Fast"
}

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var gameModel: GameViewModel
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            header

            Divider()

            gameLevelPicker
            
            Divider()
            
            animationSpeedToggle
            
            Divider()
            
            cloudSyncSection // Added cloud sync section
            
            Divider()
            
            perfectBoardButton
            
            Spacer()
            
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
        }
    }
    
    @ViewBuilder private var cloudSyncSection: some View {
        VStack(alignment: .leading) {
            Text("Cloud Sync").bold()
            HStack {
                Button {
                    gameModel.saveGameState()
                } label: {
                    Label("Save Game to Cloud", systemImage: "icloud.and.arrow.up")
                }
                .buttonStyle(.bordered)
                .disabled(!gameModel.statusMessage.isEmpty)

                Button {
                    gameModel.applyVersionChoice(useCloud: true)
                } label: {
                    Label("Load Game from Cloud", systemImage: "icloud.and.arrow.down")
                }
                .buttonStyle(.bordered)
                .disabled(!gameModel.statusMessage.isEmpty)
            }
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
    
    @ViewBuilder private var perfectBoardButton: some View {
        VStack(alignment: .center) {
            
            Button(action: {
                gameModel.setPerfectBoard()
                presentationMode.wrappedValue.dismiss()
            }) {
                Label("Show The Perfect Board!", systemImage: "star.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .padding()
    }
    
    @ViewBuilder private var contactView: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack {
                Text("Send us your feedback!")
                Link("Visit site", destination: URL(string: "https://lucaslongo.com/quest131072/")!)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(5)
            }
        }
    }
}
