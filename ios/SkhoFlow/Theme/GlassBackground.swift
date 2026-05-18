import SwiftUI

/// Liquid-glass card: ultraThinMaterial floor with translucent tint + hairline stroke.
struct GlassCard<Content: View>: View {
    var radius: CGFloat = 22
    var strokeAccent: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(SkhoFlowTheme.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .stroke(strokeAccent ? SkhoFlowTheme.strokeAccent : SkhoFlowTheme.strokeFaint,
                                    lineWidth: 1)
                    )
            )
    }
}

/// Hero glass card with crimson tint and accent border.
struct HeroGlassCard<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .fill(SkhoFlowTheme.heroGradient)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(SkhoFlowTheme.strokeAccent, lineWidth: 1)
                    )
            )
    }
}

/// Primary CTA: crimson gradient pill with subtle glow.
struct AccentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.vertical, 14)
            .padding(.horizontal, 22)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(SkhoFlowTheme.accentGradient)
                    .shadow(color: SkhoFlowTheme.hotRed.opacity(0.45), radius: 16, y: 4)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Secondary glass pill button.
struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(SkhoFlowTheme.textPrimary)
            .padding(.vertical, 12)
            .padding(.horizontal, 18)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(SkhoFlowTheme.strokeFaint, lineWidth: 1)
                    )
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

/// Page background — matte black with a single crimson aurora glow.
struct SkhoFlowBackground: View {
    var body: some View {
        ZStack {
            SkhoFlowTheme.background
            SkhoFlowTheme.accentGlow
                .frame(width: 600, height: 600)
                .blur(radius: 80)
                .offset(x: -120, y: -260)
                .opacity(0.65)
        }
        .ignoresSafeArea()
    }
}
