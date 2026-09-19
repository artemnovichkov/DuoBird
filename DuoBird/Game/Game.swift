import CoreGraphics
import Foundation
import Observation

/// The rules and physics of DuoBird. Views call `step(to:size:)` every frame and `flap()` on input.
@Observable
final class Game {
    enum Phase {
        case ready, playing, over
    }

    struct Pipe {
        var x: Double
        /// The vertical center of the gap.
        var gapY: Double
        var isPassed = false
    }

    static let birdRadius = 21.0
    static let pipeWidth = 76.0
    static let groundHeight = 96.0

    // Flapping with a hinge is slower than tapping, so the physics is gentler than the original.
    private let gravity = 1_350.0
    private let flapVelocity = -470.0
    private let pipeSpacing = 290.0

    private(set) var phase = Phase.ready
    private(set) var birdY = 0.0
    private(set) var velocity = 0.0
    private(set) var pipes: [Pipe] = []
    private(set) var score = 0
    private(set) var best = UserDefaults.standard.integer(forKey: "best")
    /// Counts flaps, for haptics and the wing animation.
    private(set) var flaps = 0
    /// How far the world has scrolled, in points.
    private(set) var distance = 0.0
    /// Seconds since launch, in game time.
    private(set) var time = 0.0
    private(set) var size = CGSize.zero

    private var lastDate: Date?
    private var lastFlapTime = -1.0
    private var gameOverTime = 0.0

    var birdX: Double { size.width * 0.3 }
    var groundY: Double { size.height - Self.groundHeight }
    /// The gap grows on tall screens, so the inner display isn't harder than the outer one.
    var gapHeight: Double { max(190, size.height * 0.24) }
    var speed: Double { 165 + Double(min(score, 30)) * 3 }

    /// Nose up after a flap, nose down while falling.
    var birdAngle: Double {
        phase == .ready ? 0 : min(max(velocity / 700, -0.45), 1.4)
    }

    /// 0...1, drives the wing. Beats fast right after a flap.
    var wingPhase: Double {
        guard phase != .over else { return 0.5 }
        let sinceFlap = time - lastFlapTime
        let rate = sinceFlap < 0.3 ? 28.0 : 10.0
        return (sin(time * rate) + 1) / 2
    }

    func flap() {
        switch phase {
        case .ready:
            start()
        case .playing:
            break
        case .over:
            // A short pause, so the flap that killed you doesn't restart right away.
            guard time - gameOverTime > 0.6 else { return }
            start()
        }
        velocity = flapVelocity
        lastFlapTime = time
        flaps += 1
    }

    func step(to date: Date, size newSize: CGSize) {
        let dt = lastDate.map { min(date.timeIntervalSince($0), 1.0 / 30) } ?? 0
        lastDate = date
        if newSize != size {
            size = newSize
            if phase == .ready { birdY = size.height * 0.45 }
        }
        guard dt > 0, size.height > 0 else { return }
        time += dt

        switch phase {
        case .ready:
            birdY = size.height * 0.45 + sin(time * 3) * 8
            distance += speed * dt
        case .playing:
            fly(dt)
            distance += speed * dt
            movePipes(dt)
            if hitsSomething { end() }
        case .over:
            // Drop to the ground.
            if birdY < groundY - Self.birdRadius {
                fly(dt)
                birdY = min(birdY, groundY - Self.birdRadius)
            }
        }
    }

    private func start() {
        phase = .playing
        pipes = []
        score = 0
        birdY = size.height * 0.45
    }

    private func end() {
        phase = .over
        gameOverTime = time
        if score > best {
            best = score
            UserDefaults.standard.set(best, forKey: "best")
        }
    }

    private func fly(_ dt: Double) {
        velocity += gravity * dt
        birdY += velocity * dt
        if birdY < Self.birdRadius {
            birdY = Self.birdRadius
            velocity = 0
        }
    }

    private func movePipes(_ dt: Double) {
        for index in pipes.indices {
            pipes[index].x -= speed * dt
            if !pipes[index].isPassed, pipes[index].x + Self.pipeWidth < birdX {
                pipes[index].isPassed = true
                score += 1
            }
        }
        pipes.removeAll { $0.x < -Self.pipeWidth }

        if pipes.last.map({ $0.x < size.width - pipeSpacing }) ?? true {
            let margin = gapHeight / 2 + 50
            let range = margin...max(margin, groundY - margin)
            pipes.append(Pipe(x: size.width + Self.pipeWidth, gapY: .random(in: range)))
        }
    }

    private var hitsSomething: Bool {
        let radius = Self.birdRadius * 0.85 // A little forgiveness at the edges.
        if birdY + radius >= groundY { return true }
        return pipes.contains { pipe in
            let nearestX = min(max(birdX, pipe.x), pipe.x + Self.pipeWidth)
            let gapTop = pipe.gapY - gapHeight / 2
            let gapBottom = pipe.gapY + gapHeight / 2
            // Distance to the closest point of the upper and the lower pipe.
            let upperY = min(birdY, gapTop)
            let lowerY = max(birdY, gapBottom)
            return hypot(birdX - nearestX, birdY - upperY) < radius
                || hypot(birdX - nearestX, birdY - lowerY) < radius
        }
    }
}
