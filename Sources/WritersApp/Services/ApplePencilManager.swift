import Foundation

// MARK: - Apple Pencil Manager

/// Manages Apple Pencil features for iPad Pro writing experience
public class ApplePencilManager {

    // MARK: - Properties

    public private(set) var isConnected: Bool = false
    public private(set) var pencilGeneration: ApplePencilGeneration?
    public private(set) var batteryLevel: Double?
    public private(set) var isCharging: Bool = false

    public var configuration: PencilConfiguration

    private var strokeHistory: [PencilStroke] = []
    private var currentStroke: PencilStroke?

    // MARK: - Initialization

    public init(configuration: PencilConfiguration = PencilConfiguration()) {
        self.configuration = configuration
    }

    // MARK: - Connection Management

    /// Update pencil connection state
    public func updateConnectionState(
        isConnected: Bool,
        generation: ApplePencilGeneration?,
        batteryLevel: Double?,
        isCharging: Bool
    ) {
        self.isConnected = isConnected
        self.pencilGeneration = generation
        self.batteryLevel = batteryLevel
        self.isCharging = isCharging
    }

    // MARK: - Stroke Handling

    /// Begin a new pencil stroke
    public func beginStroke(at point: PencilPoint) {
        currentStroke = PencilStroke(
            id: UUID(),
            startTime: Date(),
            points: [point],
            tool: configuration.currentTool
        )
    }

    /// Add a point to the current stroke
    public func addPoint(_ point: PencilPoint) {
        guard var stroke = currentStroke else { return }
        stroke.points.append(point)
        currentStroke = stroke
    }

    /// End the current stroke
    public func endStroke() -> PencilStroke? {
        guard var stroke = currentStroke else { return nil }
        stroke.endTime = Date()
        strokeHistory.append(stroke)
        currentStroke = nil
        return stroke
    }

    /// Cancel the current stroke
    public func cancelStroke() {
        currentStroke = nil
    }

    // MARK: - Gesture Recognition

    /// Process a double tap gesture on Apple Pencil (2nd gen and Pro)
    public func handleDoubleTap() -> PencilAction {
        guard let generation = pencilGeneration,
              generation.supportsDoubleTap else {
            return .none
        }
        return configuration.doubleTapAction
    }

    /// Process a squeeze gesture on Apple Pencil Pro
    public func handleSqueeze() -> PencilAction {
        guard let generation = pencilGeneration,
              generation.supportsSqueeze else {
            return .none
        }
        return configuration.squeezeAction
    }

    /// Process hover data (M4 iPad Pro feature)
    public func handleHover(at point: PencilPoint, distance: Double) -> HoverInfo {
        HoverInfo(
            point: point,
            distance: distance,
            isInRange: distance <= 12.0, // 12mm hover detection range
            suggestedAction: determineHoverAction(distance: distance)
        )
    }

    private func determineHoverAction(distance: Double) -> HoverAction {
        if distance <= 3.0 {
            return .showPreciseTarget
        } else if distance <= 8.0 {
            return .showPreview
        } else {
            return .showHint
        }
    }

    // MARK: - Handwriting Support

    /// Convert pencil stroke to text using handwriting recognition
    public func convertToText(strokes: [PencilStroke]) -> HandwritingResult {
        // Basic handwriting recognition using stroke analysis
        // In production, this would integrate with Apple's Vision framework or ML models
        
        guard !strokes.isEmpty else {
            return HandwritingResult(
                recognizedText: "",
                confidence: 0.0,
                alternatives: [],
                language: configuration.handwritingLanguage
            )
        }
        
        // Analyze stroke patterns to recognize basic shapes and characters
        let recognizedText = analyzeStrokesForText(strokes)
        let confidence = calculateRecognitionConfidence(strokes: strokes)
        let alternatives = generateAlternatives(for: recognizedText, strokes: strokes)
        
        return HandwritingResult(
            recognizedText: recognizedText,
            confidence: confidence,
            alternatives: alternatives,
            language: configuration.handwritingLanguage
        )
    }
    
    // MARK: - Private Handwriting Analysis
    
    /// Analyze strokes to extract text patterns
    private func analyzeStrokesForText(_ strokes: [PencilStroke]) -> String {
        var recognizedCharacters: [String] = []
        
        for stroke in strokes {
            if let character = recognizeCharacter(from: stroke) {
                recognizedCharacters.append(character)
            }
        }
        
        return recognizedCharacters.joined(separator: "")
    }
    
    /// Recognize a single character from a stroke
    private func recognizeCharacter(from stroke: PencilStroke) -> String? {
        let box = stroke.boundingBox
        let aspectRatio = box.width / max(box.height, 0.001)
        let pointCount = stroke.points.count
        
        // Basic heuristic-based character recognition
        // Vertical lines (like 'I', 'l')
        if aspectRatio < 0.3 && pointCount > 2 {
            return "I"
        }
        
        // Horizontal lines (like '-', '_')
        if aspectRatio > 3.0 && pointCount > 2 {
            return "-"
        }
        
        // Circular shapes (like 'O', '0')
        if aspectRatio > 0.7 && aspectRatio < 1.3 && isCircularStroke(stroke) {
            return "O"
        }
        
        // Default: return a placeholder for unrecognized strokes
        return "?"
    }
    
    /// Check if a stroke forms a circular shape
    private func isCircularStroke(_ stroke: PencilStroke) -> Bool {
        guard stroke.points.count >= 4 else { return false }
        
        let firstPoint = stroke.points[0]
        let lastPoint = stroke.points[stroke.points.count - 1]
        
        // Check if start and end points are close (closed loop)
        let dx = lastPoint.x - firstPoint.x
        let dy = lastPoint.y - firstPoint.y
        let distance = sqrt(dx * dx + dy * dy)
        
        let threshold = stroke.boundingBox.width * 0.2
        return distance < threshold
    }
    
    /// Calculate confidence score based on stroke quality
    private func calculateRecognitionConfidence(strokes: [PencilStroke]) -> Double {
        guard !strokes.isEmpty else { return 0.0 }
        
        var totalConfidence = 0.0
        
        for stroke in strokes {
            // Confidence factors:
            // 1. Stroke smoothness (consistent pressure)
            let pressureVariation = calculatePressureVariation(stroke)
            let smoothnessScore = 1.0 - min(pressureVariation, 1.0)
            
            // 2. Point density (enough data points)
            let densityScore = min(Double(stroke.points.count) / 20.0, 1.0)
            
            // 3. Stroke completeness
            let completenessScore = stroke.endTime != nil ? 1.0 : 0.5
            
            totalConfidence += (smoothnessScore + densityScore + completenessScore) / 3.0
        }
        
        return totalConfidence / Double(strokes.count)
    }
    
    /// Calculate pressure variation in a stroke
    private func calculatePressureVariation(_ stroke: PencilStroke) -> Double {
        guard stroke.points.count > 1 else { return 0.0 }
        
        let avgPressure = stroke.averagePressure
        var sumSquaredDiff = 0.0
        
        for point in stroke.points {
            let diff = point.pressure - avgPressure
            sumSquaredDiff += diff * diff
        }
        
        return sqrt(sumSquaredDiff / Double(stroke.points.count))
    }
    
    /// Generate alternative interpretations
    private func generateAlternatives(for text: String, strokes: [PencilStroke]) -> [String] {
        var alternatives: [String] = []
        
        // Generate variations based on similar characters
        let replacements: [String: [String]] = [
            "I": ["l", "1", "|"],
            "O": ["0", "o", "Q"],
            "?": [".", ",", "'"]
        ]
        
        for (original, variants) in replacements {
            if text.contains(original) {
                for variant in variants {
                    let alternative = text.replacingOccurrences(of: original, with: variant)
                    if alternative != text {
                        alternatives.append(alternative)
                    }
                }
            }
        }
        
        // Limit to top 3 alternatives
        return Array(alternatives.prefix(3))
    }

    /// Check if Scribble is enabled for text fields
    public var isScribbleEnabled: Bool {
        return isConnected && configuration.scribbleEnabled
    }

    // MARK: - Drawing Tools

    /// Get the current drawing tool configuration
    public func getCurrentToolSettings() -> ToolSettings {
        ToolSettings(
            tool: configuration.currentTool,
            strokeWidth: configuration.strokeWidth,
            opacity: configuration.opacity,
            color: configuration.inkColor,
            pressureSensitivity: configuration.pressureSensitivity,
            tiltSensitivity: configuration.tiltSensitivity
        )
    }

    /// Switch to a different drawing tool
    public func switchTool(to tool: PencilTool) {
        configuration.currentTool = tool
    }

    // MARK: - Annotation Support

    /// Create an annotation from strokes
    public func createAnnotation(
        strokes: [PencilStroke],
        documentId: UUID,
        pageNumber: Int
    ) -> Annotation {
        Annotation(
            id: UUID(),
            documentId: documentId,
            pageNumber: pageNumber,
            strokes: strokes,
            createdAt: Date(),
            tool: configuration.currentTool,
            color: configuration.inkColor
        )
    }

    // MARK: - History Management

    /// Get stroke history
    public func getStrokeHistory() -> [PencilStroke] {
        return strokeHistory
    }

    /// Clear stroke history
    public func clearHistory() {
        strokeHistory.removeAll()
    }

    /// Undo last stroke
    public func undoLastStroke() -> PencilStroke? {
        return strokeHistory.popLast()
    }
}

// MARK: - Pencil Configuration

/// Configuration for Apple Pencil behavior
public struct PencilConfiguration: Codable {
    public var doubleTapAction: PencilAction
    public var squeezeAction: PencilAction
    public var currentTool: PencilTool
    public var strokeWidth: Double
    public var opacity: Double
    public var inkColor: String // Hex color
    public var pressureSensitivity: Double
    public var tiltSensitivity: Double
    public var scribbleEnabled: Bool
    public var handwritingLanguage: String
    public var palmRejectionSensitivity: PalmRejectionLevel

    public init(
        doubleTapAction: PencilAction = .switchTool,
        squeezeAction: PencilAction = .showToolPicker,
        currentTool: PencilTool = .pen,
        strokeWidth: Double = 2.0,
        opacity: Double = 1.0,
        inkColor: String = "#000000",
        pressureSensitivity: Double = 1.0,
        tiltSensitivity: Double = 1.0,
        scribbleEnabled: Bool = true,
        handwritingLanguage: String = "en-US",
        palmRejectionSensitivity: PalmRejectionLevel = .medium
    ) {
        self.doubleTapAction = doubleTapAction
        self.squeezeAction = squeezeAction
        self.currentTool = currentTool
        self.strokeWidth = strokeWidth
        self.opacity = opacity
        self.inkColor = inkColor
        self.pressureSensitivity = pressureSensitivity
        self.tiltSensitivity = tiltSensitivity
        self.scribbleEnabled = scribbleEnabled
        self.handwritingLanguage = handwritingLanguage
        self.palmRejectionSensitivity = palmRejectionSensitivity
    }
}

// MARK: - Pencil Actions

/// Actions that can be triggered by Apple Pencil gestures
public enum PencilAction: String, Codable, CaseIterable {
    case none
    case switchTool
    case showToolPicker
    case toggleEraser
    case undo
    case redo
    case showColorPicker
    case toggleInkMode
    case showAIMenu
    case insertNewLine
    case quickNote

    public var displayName: String {
        switch self {
        case .none: return "None"
        case .switchTool: return "Switch Tool"
        case .showToolPicker: return "Show Tool Picker"
        case .toggleEraser: return "Toggle Eraser"
        case .undo: return "Undo"
        case .redo: return "Redo"
        case .showColorPicker: return "Show Color Picker"
        case .toggleInkMode: return "Toggle Ink Mode"
        case .showAIMenu: return "Show AI Menu"
        case .insertNewLine: return "Insert New Line"
        case .quickNote: return "Quick Note"
        }
    }
}

// MARK: - Pencil Tools

/// Drawing tools available with Apple Pencil
public enum PencilTool: String, Codable, CaseIterable {
    case pen
    case pencil
    case marker
    case highlighter
    case eraser
    case selection
    case lasso

    public var displayName: String {
        switch self {
        case .pen: return "Pen"
        case .pencil: return "Pencil"
        case .marker: return "Marker"
        case .highlighter: return "Highlighter"
        case .eraser: return "Eraser"
        case .selection: return "Selection"
        case .lasso: return "Lasso"
        }
    }

    /// Default stroke width for each tool
    public var defaultStrokeWidth: Double {
        switch self {
        case .pen: return 2.0
        case .pencil: return 1.5
        case .marker: return 8.0
        case .highlighter: return 20.0
        case .eraser: return 10.0
        case .selection, .lasso: return 1.0
        }
    }

    /// Whether the tool responds to pressure
    public var supportsPressure: Bool {
        switch self {
        case .pen, .pencil, .marker: return true
        case .highlighter, .eraser, .selection, .lasso: return false
        }
    }

    /// Whether the tool responds to tilt
    public var supportsTilt: Bool {
        switch self {
        case .pencil, .marker: return true
        case .pen, .highlighter, .eraser, .selection, .lasso: return false
        }
    }
}

// MARK: - Pencil Point

/// Represents a point captured from Apple Pencil
public struct PencilPoint: Codable {
    public let x: Double
    public let y: Double
    public let pressure: Double      // 0.0 to 1.0
    public let altitude: Double      // Radians (0 = parallel to surface)
    public let azimuth: Double       // Radians (angle of tilt direction)
    public let timestamp: TimeInterval
    public let estimatedProperties: EstimatedProperties?

    public init(
        x: Double,
        y: Double,
        pressure: Double = 1.0,
        altitude: Double = .pi / 2,
        azimuth: Double = 0,
        timestamp: TimeInterval = Date().timeIntervalSince1970,
        estimatedProperties: EstimatedProperties? = nil
    ) {
        self.x = x
        self.y = y
        self.pressure = pressure
        self.altitude = altitude
        self.azimuth = azimuth
        self.timestamp = timestamp
        self.estimatedProperties = estimatedProperties
    }
}

/// Properties that may be estimated initially
public struct EstimatedProperties: Codable, OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let pressure = EstimatedProperties(rawValue: 1 << 0)
    public static let altitude = EstimatedProperties(rawValue: 1 << 1)
    public static let azimuth = EstimatedProperties(rawValue: 1 << 2)
    public static let location = EstimatedProperties(rawValue: 1 << 3)
}

// MARK: - Pencil Stroke

/// Represents a complete pencil stroke
public struct PencilStroke: Codable, Identifiable {
    public let id: UUID
    public let startTime: Date
    public var endTime: Date?
    public var points: [PencilPoint]
    public let tool: PencilTool

    public init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        endTime: Date? = nil,
        points: [PencilPoint] = [],
        tool: PencilTool = .pen
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.points = points
        self.tool = tool
    }

    /// Duration of the stroke
    public var duration: TimeInterval? {
        guard let end = endTime else { return nil }
        return end.timeIntervalSince(startTime)
    }

    /// Bounding box of the stroke
    public var boundingBox: BoundingBox {
        guard !points.isEmpty else {
            return BoundingBox(minX: 0, minY: 0, maxX: 0, maxY: 0)
        }

        var minX = points[0].x
        var minY = points[0].y
        var maxX = points[0].x
        var maxY = points[0].y

        for point in points {
            minX = min(minX, point.x)
            minY = min(minY, point.y)
            maxX = max(maxX, point.x)
            maxY = max(maxY, point.y)
        }

        return BoundingBox(minX: minX, minY: minY, maxX: maxX, maxY: maxY)
    }

    /// Average pressure of the stroke
    public var averagePressure: Double {
        guard !points.isEmpty else { return 0 }
        return points.reduce(0) { $0 + $1.pressure } / Double(points.count)
    }
}

/// Bounding box for a stroke
public struct BoundingBox: Codable {
    public let minX: Double
    public let minY: Double
    public let maxX: Double
    public let maxY: Double

    public var width: Double { maxX - minX }
    public var height: Double { maxY - minY }
}

// MARK: - Tool Settings

/// Current settings for the drawing tool
public struct ToolSettings {
    public let tool: PencilTool
    public let strokeWidth: Double
    public let opacity: Double
    public let color: String
    public let pressureSensitivity: Double
    public let tiltSensitivity: Double
}

// MARK: - Hover Info

/// Information about hover state (M4 iPad Pro)
public struct HoverInfo {
    public let point: PencilPoint
    public let distance: Double // mm from surface
    public let isInRange: Bool
    public let suggestedAction: HoverAction
}

/// Actions suggested based on hover distance
public enum HoverAction {
    case none
    case showHint
    case showPreview
    case showPreciseTarget
}

// MARK: - Handwriting Recognition

/// Result from handwriting recognition
public struct HandwritingResult {
    public let recognizedText: String
    public let confidence: Double
    public let alternatives: [String]
    public let language: String
}

// MARK: - Annotation

/// An annotation created with Apple Pencil
public struct Annotation: Codable, Identifiable {
    public let id: UUID
    public let documentId: UUID
    public let pageNumber: Int
    public let strokes: [PencilStroke]
    public let createdAt: Date
    public let tool: PencilTool
    public let color: String

    public init(
        id: UUID = UUID(),
        documentId: UUID,
        pageNumber: Int,
        strokes: [PencilStroke],
        createdAt: Date = Date(),
        tool: PencilTool,
        color: String
    ) {
        self.id = id
        self.documentId = documentId
        self.pageNumber = pageNumber
        self.strokes = strokes
        self.createdAt = createdAt
        self.tool = tool
        self.color = color
    }
}

// MARK: - Palm Rejection

/// Palm rejection sensitivity levels
public enum PalmRejectionLevel: String, Codable, CaseIterable {
    case low
    case medium
    case high
    case automatic

    public var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .automatic: return "Automatic"
        }
    }
}

// MARK: - Writing Surface

/// Configuration for the writing surface
public struct WritingSurfaceConfiguration: Codable {
    public var paperTexture: PaperTexture
    public var gridStyle: GridStyle
    public var lineSpacing: Double
    public var marginWidth: Double
    public var backgroundColor: String

    public init(
        paperTexture: PaperTexture = .smooth,
        gridStyle: GridStyle = .none,
        lineSpacing: Double = 32,
        marginWidth: Double = 40,
        backgroundColor: String = "#FFFFFF"
    ) {
        self.paperTexture = paperTexture
        self.gridStyle = gridStyle
        self.lineSpacing = lineSpacing
        self.marginWidth = marginWidth
        self.backgroundColor = backgroundColor
    }
}

/// Paper texture options
public enum PaperTexture: String, Codable, CaseIterable {
    case smooth
    case textured
    case canvas
    case parchment

    public var displayName: String {
        switch self {
        case .smooth: return "Smooth"
        case .textured: return "Textured"
        case .canvas: return "Canvas"
        case .parchment: return "Parchment"
        }
    }
}

/// Grid style options
public enum GridStyle: String, Codable, CaseIterable {
    case none
    case lines
    case dots
    case graph
    case isometric

    public var displayName: String {
        switch self {
        case .none: return "None"
        case .lines: return "Lines"
        case .dots: return "Dots"
        case .graph: return "Graph"
        case .isometric: return "Isometric"
        }
    }
}
