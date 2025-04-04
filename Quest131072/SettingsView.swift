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
            .pickerStyle(SegmentedPickerStyle())
            
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
    
    @ViewBuilder private var contactView: some View {
        HStack {
            Text("Send us your feedback!")
            Link("Visit site", destination: URL(string: "https://lucaslongo.com/speed2048/")!)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(5)
            
        }
    }
}
