#if canImport(SwiftUI)
import SwiftUI

/// Centralized design system tokens
/// Never hardcode values - always reference these tokens
@available(iOS 16.0, macOS 13.0, *)
enum DesignTokens {

    // MARK: - Colors

    enum Colors {
        static let primary = Color("Primary") // #2563eb in Assets
        static let primaryHover = Color("PrimaryHover") // #1d4ed8
        static let surface = Color("Surface") // #ffffff
        static let text = Color("Text") // #1a1a1a
        static let textMuted = Color("TextMuted") // #6b7280
        static let border = Color("Border") // #e5e7eb
        static let error = Color("Error") // #dc2626
        static let success = Color("Success") // #16a34a

        // Semantic aliases for context
        static let background = surface
        static let foreground = text
        static let destructive = error
    }

    // MARK: - Typography

    enum Typography {
        // Font families
        static let sans = Font.system(.body, design: .default)
        static let mono = Font.system(.body, design: .monospaced)

        // Font sizes (SwiftUI Text styles map to iOS Dynamic Type)
        static let xs = Font.system(size: 12) // 0.75rem
        static let sm = Font.system(size: 14) // 0.875rem
        static let base = Font.system(size: 16) // 1rem
        static let lg = Font.system(size: 18) // 1.125rem
        static let xl = Font.system(size: 20) // 1.25rem
        static let xxl = Font.system(size: 24) // 1.5rem

        // Semantic type styles
        static let title = Font.system(size: 28, weight: .bold)
        static let headline = Font.system(size: 20, weight: .semibold)
        static let body = Font.system(size: 16, weight: .regular)
        static let callout = Font.system(size: 15, weight: .regular)
        static let caption = Font.system(size: 12, weight: .regular)

        // Line spacing
        static let lineSpacingTight: CGFloat = 1.25
        static let lineSpacingNormal: CGFloat = 1.5
        static let lineSpacingRelaxed: CGFloat = 1.75
    }

    // MARK: - Spacing

    enum Spacing {
        static let xxxs: CGFloat = 2   // 0.125rem
        static let xxs: CGFloat = 4    // 0.25rem
        static let xs: CGFloat = 8     // 0.5rem
        static let sm: CGFloat = 12    // 0.75rem
        static let md: CGFloat = 16    // 1rem
        static let lg: CGFloat = 24    // 1.5rem
        static let xl: CGFloat = 32    // 2rem
        static let xxl: CGFloat = 48   // 3rem
        static let xxxl: CGFloat = 64  // 4rem

        // Semantic aliases
        static let padding = md
        static let gap = md
        static let margin = lg
    }

    // MARK: - Borders & Radii

    enum Radius {
        static let none: CGFloat = 0
        static let sm: CGFloat = 4
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
        static let full: CGFloat = 999 // Pill shape
    }

    enum Border {
        static let width: CGFloat = 1
        static let widthThick: CGFloat = 2
    }

    // MARK: - Shadows

    enum Shadow {
        static let sm: CGFloat = 2
        static let md: CGFloat = 4
        static let lg: CGFloat = 8
        static let xl: CGFloat = 12

        // Shadow styles for .shadow() modifier
        static func small(color: Color = .black.opacity(0.05)) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            (color, 2, 0, 1)
        }

        static func medium(color: Color = .black.opacity(0.07)) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            (color, 6, 0, 4)
        }

        static func large(color: Color = .black.opacity(0.1)) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            (color, 15, 0, 10)
        }
    }

    // MARK: - Transitions/Animations

    enum Duration {
        static let fast: Double = 0.15    // 150ms
        static let normal: Double = 0.25  // 250ms
        static let slow: Double = 0.4     // 400ms
    }

    enum Easing {
        static let `default` = Animation.timingCurve(0.4, 0, 0.2, 1)
        static let easeIn = Animation.easeIn
        static let easeOut = Animation.easeOut
        static let easeInOut = Animation.easeInOut
        static let spring = Animation.spring(response: 0.3, dampingFraction: 0.7)
    }

    // MARK: - Z-Index (Layer Priority)

    enum ZIndex {
        static let base: Double = 0
        static let dropdown: Double = 100
        static let sticky: Double = 200
        static let overlay: Double = 300
        static let modal: Double = 400
        static let popover: Double = 500
        static let toast: Double = 600
        static let tooltip: Double = 700
    }

    // MARK: - Breakpoints (for GeometryReader conditionals)

    enum Breakpoint {
        static let sm: CGFloat = 640
        static let md: CGFloat = 768
        static let lg: CGFloat = 1024
        static let xl: CGFloat = 1280
        static let xxl: CGFloat = 1536
    }
}

// MARK: - Convenience Extensions

@available(iOS 16.0, macOS 13.0, *)
extension View {
    /// Apply small shadow
    func shadowSmall() -> some View {
        let s = DesignTokens.Shadow.small()
        return self.shadow(color: s.color, radius: s.radius, x: s.x, y: s.y)
    }

    /// Apply medium shadow
    func shadowMedium() -> some View {
        let s = DesignTokens.Shadow.medium()
        return self.shadow(color: s.color, radius: s.radius, x: s.x, y: s.y)
    }

    /// Apply large shadow
    func shadowLarge() -> some View {
        let s = DesignTokens.Shadow.large()
        return self.shadow(color: s.color, radius: s.radius, x: s.x, y: s.y)
    }
}
#endif
