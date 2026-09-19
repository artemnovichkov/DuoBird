import SwiftUI

/// Flappy Bird for the iPhone Duo: snap the hinge open to flap.
///
/// Hold the device half open, like a book. Each quick unfold is one flap.
/// Fold back a little to get ready for the next one. Tapping works too.
struct GameView: View {
    @State private var game = Game()
    @State private var flapDetector = FlapDetector()
    @State private var hinge: DeviceHinge?

    var body: some View {
        GeometryReader { proxy in
            TimelineView(.animation) { timeline in
                Scenery(game: game)
                    .onChange(of: timeline.date, initial: true) { _, date in
                        game.step(to: date, size: proxy.size)
                    }
            }
        }
        .ignoresSafeArea()
        .overlay {
            Overlay(game: game, hinge: hinge)
        }
        .contentShape(.rect)
        .onTapGesture {
            game.flap()
        }
        // 👇 The API: every quick unfold of the hinge is a flap.
        .onHingeChange { _, newContext in
            hinge = newContext.hinge
            guard let degrees = newContext.hinge?.angle.degrees else { return }
            if flapDetector.update(degrees: degrees) {
                game.flap()
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: game.flaps)
        .sensoryFeedback(.error, trigger: game.phase) { _, phase in phase == .over }
    }
}

/// Title, score, and game-over card on top of the scene.
private struct Overlay: View {
    let game: Game
    let hinge: DeviceHinge?

    var body: some View {
        VStack {
            if game.phase != .ready {
                score
            }
            switch game.phase {
            case .ready:
                Text("DuoBird")
                    .font(.system(size: 64, weight: .black, design: .rounded))
                    .outlined()
                    .padding(.top, 60)
                Spacer()
                Text(hint)
                    .font(.title2.weight(.heavy))
                    .fontDesign(.rounded)
                    .outlined()
                    .multilineTextAlignment(.center)
                    .padding(.bottom, Game.groundHeight + 40)
            case .playing:
                Spacer()
            case .over:
                Spacer()
                GameOverCard(score: game.score, best: game.best, hint: hint)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .bottomLeading) {
            if let hinge {
                Label(hinge.angle.degrees.formatted(.number.precision(.fractionLength(0))) + "°", systemImage: "book")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.brown)
                    .padding()
            }
        }
        .allowsHitTesting(false)
        .animation(.snappy, value: game.phase)
    }

    private var score: some View {
        Text(game.score, format: .number)
            .font(.system(size: 72, weight: .black, design: .rounded))
            .monospacedDigit()
            .outlined()
            .contentTransition(.numericText(value: Double(game.score)))
            .animation(.snappy, value: game.score)
            .padding(.top, 40)
    }

    private var hint: String {
        hinge == nil ? "Tap to flap" : "Hold it half open.\nSnap the hinge open to flap."
    }
}

private struct GameOverCard: View {
    let score: Int
    let best: Int
    let hint: String

    var body: some View {
        VStack(spacing: 12) {
            Text("Game Over")
                .font(.system(size: 44, weight: .black, design: .rounded))
                .outlined()
            HStack(spacing: 32) {
                stat("Score", score)
                stat("Best", best)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(Color(red: 0.87, green: 0.84, blue: 0.58), in: .rect(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12).strokeBorder(.brown, lineWidth: 3)
            }
            Text(hint.replacingOccurrences(of: "flap", with: "try again"))
                .font(.headline.weight(.heavy))
                .fontDesign(.rounded)
                .outlined()
                .multilineTextAlignment(.center)
        }
        .transition(.scale.combined(with: .opacity))
    }

    private func stat(_ title: String, _ value: Int) -> some View {
        VStack {
            Text(title)
                .font(.headline.weight(.heavy))
                .foregroundStyle(.orange)
            Text(value, format: .number)
                .font(.system(size: 36, weight: .black, design: .rounded))
                .monospacedDigit()
                .outlined()
        }
    }
}

private extension View {
    /// White text with a black outline, like the original.
    func outlined() -> some View {
        foregroundStyle(.white)
            .shadow(color: .black, radius: 0, x: 2, y: 2)
            .shadow(color: .black, radius: 0, x: -1, y: -1)
            .shadow(color: .black, radius: 0, x: 2, y: -1)
            .shadow(color: .black, radius: 0, x: -1, y: 2)
            // Fade the outlined text as one layer, or the stacked shadows turn it gray.
            .compositingGroup()
    }
}

#Preview {
    GameView()
}
