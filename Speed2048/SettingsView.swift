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
    
    @ViewBuilder private var gameLevelPicker: some View {
        VStack(alignment: .center) {
            Text("Game Level").bold()
            Picker("Game Level", selection: $gameModel.gameLevel) {
                ForEach(GameLevel.allCases, id: \.self) { level in
                    Text(level.rawValue).tag(level)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            Text("Penalty: \(gameModel.gameLevel.penaltyAmount)s")
        }
        .padding()
    }

    @ViewBuilder private var timesToBeat: some View {
        
        let columns = [
            GridItem(.flexible(), alignment: .center),
            GridItem(.flexible(), alignment: .center),
            GridItem(.flexible(), alignment: .center)
        ]
        
        LazyVGrid(columns: columns, spacing: 10) {
            // Table headers
            Label("Number", systemImage: "number")
            Label("Beat", systemImage: "trophy")
            Label("Current", systemImage: "figure.run")
            
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
 
    func fgColor(tile: Int) -> Color {
        if let curr = gameModel.secondsSinceLast(for: tile), let avg = gameModel.averageTime(for: tile) {
            return Double(curr) > avg ? .red : .green
        }
        
        return .black
    }
}
