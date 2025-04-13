import SwiftUI

struct ScoreView: View {
    @ObservedObject var gameModel: GameViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            Text("Score")
                .font(.headline)
                .padding()

            Text("\(gameModel.totalScore)")
                .font(.largeTitle)
                .bold()
                .padding()

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Level", systemImage: "quotelevel")
                    Spacer()
                    Text("\(gameModel.gameLevel)")
                }
                HStack {
                    Label("Time", systemImage: "clock")
                    Spacer()
                    Text(gameModel.seconds.formattedAsTime)
                }
                HStack {
                    Label("Undos", systemImage: "arrow.uturn.backward.circle")
                    Spacer()
                    Text("\(gameModel.undosUsed)")
                }
            }
            .padding()

            Spacer()

            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
