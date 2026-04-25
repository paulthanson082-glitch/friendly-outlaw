#if canImport(SwiftUI)
import SwiftUI

@available(iOS 16.0, macOS 13.0, *)
public struct DayDisplayWidget: View {
    @State private var currentDate = Date()
    @State private var isAnimating = false
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    public var body: some View {
        ZStack {
            MetalTheme.obsidian
                .ignoresSafeArea()

            VStack(spacing: 12) {
                dayOfWeekView
                dayNumberView
                timeView
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onReceive(timer) { _ in
            currentDate = Date()
        }
    }

    private var dayOfWeekView: some View {
        Text(dayOfWeek)
            .font(.caption)
            .tracking(2.0)
            .foregroundColor(MetalTheme.steel)
            .widgetAccentable()
    }

    private var dayNumberView: some View {
        VStack(spacing: 4) {
            Text(dayNumber)
                .font(.system(size: 48, weight: .black, design: .rounded))
                .foregroundColor(MetalTheme.chrome)

            Text(monthName)
                .font(.system(size: 12, weight: .semibold, design: .default))
                .tracking(1.5)
                .foregroundColor(MetalTheme.steel)
        }
    }

    private var timeView: some View {
        VStack(spacing: 4) {
            Text(timeString)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(MetalTheme.crimson)

            Divider()
                .background(MetalTheme.chainLink)

            Text(dayOfWeekFull)
                .font(.system(size: 11, weight: .regular, design: .default))
                .tracking(1.0)
                .foregroundColor(MetalTheme.steel)
        }
    }

    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: currentDate).uppercased()
    }

    private var dayOfWeekFull: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: currentDate)
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: currentDate)
    }

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: currentDate)
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: currentDate)
    }

    public init() {}
}

@available(iOS 16.0, macOS 13.0, *)
#Preview {
    DayDisplayWidget()
        .preferredColorScheme(.dark)
}
#endif
