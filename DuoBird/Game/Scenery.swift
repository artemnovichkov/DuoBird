import SwiftUI

/// Draws one frame of the game: sky, clouds, hills, pipes, ground, and the bird.
struct Scenery: View {
    let game: Game

    var body: some View {
        Canvas { context, size in
            drawSky(in: &context, size: size)
            drawPipes(in: &context, size: size)
            drawGround(in: &context, size: size)
            context.drawBird(
                at: CGPoint(x: game.birdX, y: game.birdY),
                radius: Game.birdRadius,
                angle: game.birdAngle,
                wing: game.wingPhase
            )
        }
        .accessibilityLabel("DuoBird")
    }

    private func drawSky(in context: inout GraphicsContext, size: CGSize) {
        let sky = Path(CGRect(origin: .zero, size: size))
        context.fill(sky, with: .linearGradient(
            Gradient(colors: [Color(red: 0.31, green: 0.75, blue: 0.87), Color(red: 0.72, green: 0.92, blue: 0.95)]),
            startPoint: .zero,
            endPoint: CGPoint(x: 0, y: size.height)
        ))

        // Clouds drift slowly; hills a bit faster. Both repeat forever.
        let cloudTile = 340.0
        let cloudShift = (game.distance * 0.15).truncatingRemainder(dividingBy: cloudTile)
        var x = -cloudShift
        var index = 0
        while x < size.width + cloudTile {
            let y = size.height * (0.12 + 0.1 * Double((index + Int(game.distance * 0.15 / cloudTile)) % 3))
            for (dx, dy, d) in [(0.0, 10.0, 60.0), (38, 0, 76), (86, 12, 56)] {
                context.fill(Path(ellipseIn: CGRect(x: x + dx, y: y + dy, width: d, height: d * 0.8)), with: .color(.white.opacity(0.9)))
            }
            x += cloudTile
            index += 1
        }

        let hillTile = 220.0
        let hillShift = (game.distance * 0.4).truncatingRemainder(dividingBy: hillTile)
        let hillY = game.groundY
        x = -hillShift - hillTile
        while x < size.width + hillTile {
            context.fill(Path(ellipseIn: CGRect(x: x, y: hillY - 70, width: hillTile * 1.3, height: 160)), with: .color(Color(red: 0.45, green: 0.8, blue: 0.47)))
            x += hillTile
        }
    }

    private func drawPipes(in context: inout GraphicsContext, size: CGSize) {
        let width = Game.pipeWidth
        let lipHeight = 28.0
        let lipOverhang = 5.0
        let body = Color(red: 0.45, green: 0.75, blue: 0.18)
        let shading = Gradient(stops: [
            .init(color: body, location: 0),
            .init(color: Color(red: 0.72, green: 0.92, blue: 0.4), location: 0.3),
            .init(color: body, location: 0.55),
            .init(color: Color(red: 0.3, green: 0.55, blue: 0.1), location: 1),
        ])

        for pipe in game.pipes {
            let gapTop = pipe.gapY - game.gapHeight / 2
            let gapBottom = pipe.gapY + game.gapHeight / 2
            let parts = [
                CGRect(x: pipe.x, y: -4, width: width, height: gapTop - lipHeight + 4),
                CGRect(x: pipe.x - lipOverhang, y: gapTop - lipHeight, width: width + lipOverhang * 2, height: lipHeight),
                CGRect(x: pipe.x - lipOverhang, y: gapBottom, width: width + lipOverhang * 2, height: lipHeight),
                CGRect(x: pipe.x, y: gapBottom + lipHeight, width: width, height: game.groundY - gapBottom - lipHeight),
            ]
            for rect in parts where rect.height > 0 {
                let path = Path(rect)
                context.fill(path, with: .linearGradient(shading, startPoint: CGPoint(x: rect.minX, y: 0), endPoint: CGPoint(x: rect.maxX, y: 0)))
                context.stroke(path, with: .color(.black), lineWidth: 2.5)
            }
        }
    }

    private func drawGround(in context: inout GraphicsContext, size: CGSize) {
        let top = game.groundY
        context.fill(Path(CGRect(x: 0, y: top, width: size.width, height: size.height - top)), with: .color(Color(red: 0.87, green: 0.84, blue: 0.58)))

        // Grass with diagonal stripes that scroll with the pipes.
        let grassHeight = 18.0
        context.fill(Path(CGRect(x: 0, y: top, width: size.width, height: grassHeight)), with: .color(Color(red: 0.56, green: 0.85, blue: 0.27)))
        var stripes = context
        stripes.clip(to: Path(CGRect(x: 0, y: top, width: size.width, height: grassHeight)))
        let stripe = 22.0
        var x = -game.distance.truncatingRemainder(dividingBy: stripe * 2) - stripe * 2
        while x < size.width + stripe {
            stripes.fill(Path { path in
                path.addLines([
                    CGPoint(x: x, y: top + grassHeight), CGPoint(x: x + stripe, y: top + grassHeight),
                    CGPoint(x: x + stripe * 1.6, y: top), CGPoint(x: x + stripe * 0.6, y: top),
                ])
            }, with: .color(Color(red: 0.44, green: 0.74, blue: 0.2)))
            x += stripe * 2
        }

        for y in [top, top + grassHeight] {
            context.stroke(Path { path in
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }, with: .color(.black.opacity(y == top ? 1 : 0.3)), lineWidth: y == top ? 2.5 : 3)
        }
    }
}
