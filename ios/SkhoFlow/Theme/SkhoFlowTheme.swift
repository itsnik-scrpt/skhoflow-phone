import SwiftUI

enum SkhoFlowTheme {
    static let crimson = Color(red: 225/255, green: 29/255, blue: 42/255)
    static let hotRed  = Color(red: 255/255, green: 41/255, blue: 55/255)
    static let deep    = Color(red: 138/255, green: 6/255,  blue: 18/255)

    static let background      = Color(red: 0.0, green: 0.0, blue: 0.0)
    static let surface         = Color.white.opacity(0.06)
    static let surfaceElevated = Color.white.opacity(0.10)
    static let surfaceHover    = Color.white.opacity(0.14)

    static let textPrimary   = Color.white
    static let textSecondary = Color.white.opacity(0.72)
    static let textTertiary  = Color.white.opacity(0.42)

    static let strokeFaint  = Color.white.opacity(0.10)
    static let strokeStrong = Color.white.opacity(0.20)
    static let strokeAccent = crimson.opacity(0.40)

    static let accentGradient = LinearGradient(
        colors: [crimson, hotRed],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let heroGradient = LinearGradient(
        colors: [crimson.opacity(0.20), .black.opacity(0.0)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let accentGlow = RadialGradient(
        colors: [hotRed.opacity(0.40), .clear],
        center: .center, startRadius: 0, endRadius: 220
    )
}
