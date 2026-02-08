#if canImport(SwiftUI)
import SwiftUI

// MARK: - Heavy Metal Theme

/// Brutal heavy metal color scheme and styling for the iPad Pro dashboard.
/// Inspired by the darkness of Whitechapel and the raw aggression of Lamb of God.
/// Pitch-black backgrounds, blood red accents, chrome text, ember highlights.
@available(iOS 16.0, macOS 13.0, *)
public enum MetalTheme {

    // MARK: - Colors

    /// Pitch-black background — the void before the breakdown
    public static let abyss = Color(red: 0.03, green: 0.03, blue: 0.03)
    /// Dark card/surface background
    public static let obsidian = Color(red: 0.09, green: 0.09, blue: 0.09)
    /// Slightly lighter surface for nested cards
    public static let gunmetal = Color(red: 0.15, green: 0.15, blue: 0.15)
    /// Blood red primary accent — the heart of the riff
    public static let bloodRed = Color(red: 0.55, green: 0.0, blue: 0.0)
    /// Crimson for highlights and active states
    public static let crimson = Color(red: 0.86, green: 0.08, blue: 0.24)
    /// Ember orange for warm highlights — like tube amps glowing
    public static let ember = Color(red: 1.0, green: 0.27, blue: 0.0)
    /// Chrome silver for primary text
    public static let chrome = Color(red: 0.88, green: 0.88, blue: 0.88)
    /// Dimmer silver for secondary text
    public static let steel = Color(red: 0.55, green: 0.55, blue: 0.55)
    /// Faint divider/border color
    public static let chainLink = Color(red: 0.22, green: 0.22, blue: 0.22)
    /// Gold for achievements and milestones
    public static let gold = Color(red: 0.85, green: 0.65, blue: 0.13)
    /// Sickly green for streak indicators
    public static let toxicGreen = Color(red: 0.0, green: 0.75, blue: 0.25)

    // MARK: - Gradients

    /// Gradient for card accent bars — blood to fire
    public static let fireGradient = LinearGradient(
        colors: [bloodRed, crimson, ember],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Subtle background gradient for the dashboard
    public static let abyssGradient = LinearGradient(
        colors: [abyss, Color(red: 0.05, green: 0.01, blue: 0.01)],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Progress bar gradient — forging progress
    public static let forgeGradient = LinearGradient(
        colors: [crimson, ember],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Achievement/gold gradient
    public static let conquestGradient = LinearGradient(
        colors: [Color(red: 0.70, green: 0.50, blue: 0.05), gold, Color(red: 0.90, green: 0.75, blue: 0.20)],
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: - Typography Helpers

    /// Section title — brutal uppercase with wide tracking
    public static func sectionTitle(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 13, weight: .heavy, design: .default))
            .tracking(3.0)
            .foregroundColor(steel)
    }

    /// Card title
    public static func cardTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 18, weight: .bold, design: .default))
            .foregroundColor(chrome)
    }

    /// Big stat number — the kill count
    public static func statNumber(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 38, weight: .black, design: .rounded))
            .foregroundColor(chrome)
    }

    /// Stat label under a number
    public static func statLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold))
            .tracking(2.0)
            .foregroundColor(steel)
    }
}

// MARK: - Metal Card Modifier

@available(iOS 16.0, macOS 13.0, *)
public struct MetalCardModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .padding(16)
            .background(MetalTheme.obsidian)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(MetalTheme.chainLink, lineWidth: 0.5)
            )
    }
}

@available(iOS 16.0, macOS 13.0, *)
extension View {
    public func metalCard() -> some View {
        modifier(MetalCardModifier())
    }
}

// MARK: - Metal Mantras

/// Brutal motivational quotes for writers who listen to the heavy stuff.
public struct MetalMantra {
    public let quote: String
    public let attribution: String

    public static let all: [MetalMantra] = [
        // Deathcore / Whitechapel energy
        MetalMantra(
            quote: "The blank page is the silence before the breakdown. Fill it with violence.",
            attribution: "Sawblade Syntax"
        ),
        MetalMantra(
            quote: "You are the architect of your own devastation. Write it down.",
            attribution: "The Somatic Defilement"
        ),
        MetalMantra(
            quote: "Drop-tune your doubts. Let the low end carry you.",
            attribution: "Seven-String Scripture"
        ),
        MetalMantra(
            quote: "Every first draft is a pit. Throw yourself in.",
            attribution: "Exile Protocol"
        ),

        // Groove metal / Lamb of God energy
        MetalMantra(
            quote: "Walk with me in hell — that's where the best stories live.",
            attribution: "Ashes of the Wake"
        ),
        MetalMantra(
            quote: "Now you've got something to write for.",
            attribution: "Resolution Manifesto"
        ),
        MetalMantra(
            quote: "Omerta: the code of silence ends when the pen hits paper.",
            attribution: "The Sacrament of Ink"
        ),
        MetalMantra(
            quote: "Laid to rest is what your excuses should be. Write.",
            attribution: "Redneck Revision"
        ),

        // General brutal writing motivation
        MetalMantra(
            quote: "Writer's block is just the calm before the breakdown.",
            attribution: "Riff & Revise"
        ),
        MetalMantra(
            quote: "You don't find your voice. You distort it until it screams.",
            attribution: "Gain Theory"
        ),
        MetalMantra(
            quote: "Be relentless. Be loud. Be written.",
            attribution: "Volume XI Press"
        ),
        MetalMantra(
            quote: "The first draft is the soundcheck. The final draft is the wall of death.",
            attribution: "Circle Pit Publishing"
        ),
        MetalMantra(
            quote: "Through blast beats and black ink, manuscripts are forged.",
            attribution: "Blacksmith's Quill"
        ),
        MetalMantra(
            quote: "No clean vocals. No clean drafts. Just raw, unfiltered truth.",
            attribution: "Guttural Grammar"
        ),
    ]

    public static func random() -> MetalMantra {
        all.randomElement() ?? all[0]
    }
}

#endif
