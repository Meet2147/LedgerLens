import SwiftUI
import AppKit

/// Neumorphic ("soft UI") design system: a single monochrome surface out of which controls
/// appear extruded (raised) or carved (inset), using paired light/dark shadows. Adapts to
/// light and dark mode. Inner shadows are emulated with masked, blurred strokes so the app
/// keeps its macOS 13 deployment target.
enum BrandPalette {

    // MARK: - Surface & shadows

    /// The one base color everything sits on.
    static let base = dynamic(light: Color(hex: 0xE6EBF3), dark: Color(hex: 0x23262C))
    /// Top-left highlight.
    static let lightShadow = dynamic(light: Color.white, dark: Color(hex: 0x33383F))
    /// Bottom-right shadow.
    static let darkShadow = dynamic(light: Color(hex: 0xB4BECE), dark: Color(hex: 0x121418))

    // MARK: - Text

    static let textPrimary = dynamic(light: Color(hex: 0x3B4453), dark: Color(hex: 0xDCE1E9))
    static let textSecondary = dynamic(light: Color(hex: 0x828DA1), dark: Color(hex: 0x8A93A2))
    static let textFaint = dynamic(light: Color(hex: 0xAAB3C2), dark: Color(hex: 0x5B636F))

    // MARK: - Accent & semantic

    static let accent = dynamic(light: Color(hex: 0x4F7DF6), dark: Color(hex: 0x5E8BFF))
    static let aqua = dynamic(light: Color(hex: 0x36C6E6), dark: Color(hex: 0x46D2F0))
    static let debit = dynamic(light: Color(hex: 0xD6503B), dark: Color(hex: 0xFF8674))
    static let credit = dynamic(light: Color(hex: 0x1F9A6B), dark: Color(hex: 0x45D9A0))
    static let warning = dynamic(light: Color(hex: 0xB8791A), dark: Color(hex: 0xF0B44C))
    static let success = credit

    static let brandGradient = LinearGradient(
        colors: [accent, aqua], startPoint: .topLeading, endPoint: .bottomTrailing
    )

    // MARK: - Helpers

    static func dynamic(light: Color, dark: Color) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return NSColor(isDark ? dark : light)
        })
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

// MARK: - Neumorphic surface modifiers

extension View {
    /// A raised (extruded) surface: paired outer shadows on opposite corners.
    func neuRaised(_ radius: CGFloat = 18, fill: Color = BrandPalette.base, intensity: CGFloat = 1) -> some View {
        background(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(fill)
                .shadow(color: BrandPalette.darkShadow.opacity(0.9 * intensity), radius: 7, x: 5, y: 5)
                .shadow(color: BrandPalette.lightShadow.opacity(0.9 * intensity), radius: 7, x: -5, y: -5)
        )
    }

    /// An inset (carved) well: emulated inner shadow via masked, blurred, offset strokes.
    func neuInset(_ radius: CGFloat = 14, fill: Color = BrandPalette.base) -> some View {
        background(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(fill)
                .overlay(InnerShadow(radius: radius))
                .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        )
    }
}

/// Two masked, blurred, opposite-offset strokes that read as an inner shadow.
private struct InnerShadow: View {
    let radius: CGFloat

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        ZStack {
            shape
                .stroke(BrandPalette.darkShadow, lineWidth: 3)
                .blur(radius: 3)
                .offset(x: 2, y: 2)
                .mask(shape)
            shape
                .stroke(BrandPalette.lightShadow, lineWidth: 3)
                .blur(radius: 3)
                .offset(x: -2, y: -2)
                .mask(shape)
        }
    }
}

/// A raised neumorphic button that presses inward on tap.
struct NeuButtonStyle: ButtonStyle {
    var radius: CGFloat = 12
    var tint: Color = BrandPalette.textPrimary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12.5, weight: .semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 15)
            .padding(.vertical, 9)
            .modifier(PressableNeu(pressed: configuration.isPressed, radius: radius))
    }
}

private struct PressableNeu: ViewModifier {
    let pressed: Bool
    let radius: CGFloat

    func body(content: Content) -> some View {
        if pressed {
            content.neuInset(radius)
        } else {
            content.neuRaised(radius)
        }
    }
}
