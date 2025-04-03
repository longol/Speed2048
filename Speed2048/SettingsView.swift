import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var gameModel: GameViewModel

    var body: some View {
        
        VStack(alignment: .center) {
            
            header
            
            gameLevelPicker
        
            Divider()
            
            timesToBeat
            
            Spacer()
            
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
                    .foregroundColor(.black)
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
    
    @ViewBuilder private var gameLevelPicker: some View {
        VStack(alignment: .center) {
            HStack {
                Text("Game Level").bold()
                Spacer()
                Text(gameModel.gameLevel.penaltyString)
                    .font(.footnote)
            }
            Picker("Game Level", selection: $gameModel.gameLevel) {
                ForEach(GameLevel.allCases, id: \.self) { level in
                    Text(level.rawValue).tag(level)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            
        }
        .padding()
    }

    @ViewBuilder private var timesToBeat: some View {
        
        let columns = [
            GridItem(.flexible(), alignment: .center),
            GridItem(.flexible(), alignment: .center),
            GridItem(.flexible(), alignment: .center)
        ]
        
        VStack(spacing: 0) {
            
            // Table headers
            HStack {
                Label("Number", systemImage: "number").frame(maxWidth: .infinity)
                Label("Beat", systemImage: "trophy").frame(maxWidth: .infinity)
                Label("Current", systemImage: "figure.run").frame(maxWidth: .infinity)
            }
            ScrollView {
                
                LazyVGrid(columns: columns, spacing: 10) {
                    
                    ForEach(gameModel.tileDurations.keys.sorted(by: >), id: \.self) { tile in
                        Group {
                            Text("\(tile)").bold()
                            
                            Group {
                                Text(gameModel.averageTimeString(for: tile))
                                Text(gameModel.currentTimeString(for: tile))
                            }
                            .foregroundColor(fgColor(tile: tile))
                        }
                        
                    }
                }
                .padding()
            }
        }
    }
 
    func fgColor(tile: Int) -> Color {
        if let curr = gameModel.secondsSinceLast(for: tile), let avg = gameModel.averageTime(for: tile) {
            return Double(curr) > avg ? .red : .green
        }
        
        return .black
    }
}
