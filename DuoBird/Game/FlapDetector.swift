/// Turns a stream of hinge angles into flaps.
///
/// A flap is a quick snap open: the hinge opens by `threshold` degrees
/// from its lowest point. After a flap, the detector waits until the hinge
/// folds back by `rearm` degrees, so one long unfold counts as one flap.
struct FlapDetector {
    /// How far the hinge must open, in degrees, to flap.
    var threshold = 10.0
    /// How far the hinge must fold back, in degrees, before the next flap.
    var rearm = 5.0

    private var isArmed = true
    private var lowest: Double?
    private var highest = 0.0

    /// Feeds the next hinge angle. Returns `true` when it completes a flap.
    mutating func update(degrees: Double) -> Bool {
        if isArmed {
            let low = min(lowest ?? degrees, degrees)
            lowest = low
            if degrees - low >= threshold {
                isArmed = false
                highest = degrees
                return true
            }
        } else {
            highest = max(highest, degrees)
            if highest - degrees >= rearm {
                isArmed = true
                lowest = degrees
            }
        }
        return false
    }
}
