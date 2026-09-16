import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 24) {
                Text("Kana Compass")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(Color.accentColor)
                    .scaleEffect(2)
                    .padding()
            }
            .offset(y: -30)
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(.systemBackground), Color.accentColor.opacity(0.08)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

#Preview {
    LoadingView()
}
