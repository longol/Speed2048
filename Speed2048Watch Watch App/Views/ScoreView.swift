import SwiftUI

struct ScoreView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            Text("Score")
                .font(.headline)
                .padding()

            Text("\(gameManager.totalScore)")
                .font(.largeTitle)
                .bold()
                .padding()

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Level", systemImage: "quotelevel")
                    Spacer()
                    Text("\($gameManager.gameLevel)")
                }
                HStack {
                    Label("Time", systemImage: "clock")
                    Spacer()
                    Text(gameManager.seconds.formattedAsTime)
                }
                HStack {
                    Label("Undos", systemImage: "arrow.uturn.backward.circle")
                    Spacer()
                    Text("\(gameManager.undosUsed)")
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
