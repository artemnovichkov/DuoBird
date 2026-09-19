import SwiftUI

extension GraphicsContext {
    /// Draws the bird centered at `center`.
    ///
    /// - Parameters:
    ///   - radius: Half the body height.
    ///   - angle: Rotation in radians, positive is nose down.
    ///   - wing: 0 is wing up, 1 is wing down.
    func drawBird(at center: CGPoint, radius r: Double, angle: Double, wing: Double) {
        var context = self
        context.translateBy(x: center.x, y: center.y)
        context.rotate(by: .radians(angle))
        let outline = Color.black
        let line = r * 0.14

        // Body.
        let body = Path(ellipseIn: CGRect(x: -r * 1.15, y: -r, width: r * 2.3, height: r * 2))
        context.fill(body, with: .color(Color(red: 0.98, green: 0.78, blue: 0.18)))
        let belly = Path(ellipseIn: CGRect(x: -r * 0.55, y: r * 0.1, width: r * 1.4, height: r * 0.85))
        context.fill(belly, with: .color(Color(red: 1, green: 0.93, blue: 0.62)))
        context.stroke(body, with: .color(outline), lineWidth: line)

        // Wing, pivoting at its front edge.
        var wingContext = context
        wingContext.translateBy(x: -r * 0.25, y: r * 0.05)
        wingContext.rotate(by: .radians(-0.6 + 1.2 * wing))
        let wingPath = Path(ellipseIn: CGRect(x: -r * 0.95, y: -r * 0.3, width: r * 0.95, height: r * 0.6))
        wingContext.fill(wingPath, with: .color(Color(red: 1, green: 0.97, blue: 0.85)))
        wingContext.stroke(wingPath, with: .color(outline), lineWidth: line)

        // Eye.
        let eye = Path(ellipseIn: CGRect(x: r * 0.2, y: -r * 0.8, width: r * 0.8, height: r * 0.8))
        context.fill(eye, with: .color(.white))
        context.stroke(eye, with: .color(outline), lineWidth: line)
        context.fill(Path(ellipseIn: CGRect(x: r * 0.6, y: -r * 0.52, width: r * 0.28, height: r * 0.34)), with: .color(outline))

        // Beak: two lips.
        let upperLip = Path(roundedRect: CGRect(x: r * 0.55, y: -r * 0.05, width: r * 0.95, height: r * 0.34), cornerRadius: r * 0.17)
        let lowerLip = Path(roundedRect: CGRect(x: r * 0.5, y: r * 0.27, width: r * 0.8, height: r * 0.3), cornerRadius: r * 0.15)
        for lip in [lowerLip, upperLip] {
            context.fill(lip, with: .color(Color(red: 0.96, green: 0.36, blue: 0.2)))
            context.stroke(lip, with: .color(outline), lineWidth: line)
        }
    }
}

#Preview {
    Canvas { context, size in
        context.drawBird(at: CGPoint(x: size.width / 2, y: size.height / 2), radius: 60, angle: -0.2, wing: 0.2)
    }
    .background(.cyan)
}
