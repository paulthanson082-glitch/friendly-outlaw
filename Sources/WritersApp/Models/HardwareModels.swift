import Foundation

// MARK: - Enums

/// Hardware board types supported by ZeroClaw
public enum BoardType: String, Codable, CaseIterable {
    case nucleoF401RE = "nucleo-f401re"      // STM32 Nucleo board
    case arduinoUno = "arduino-uno"          // Arduino Uno
    case rpiGPIO = "rpi-gpio"                // Raspberry Pi GPIO
    case esp32 = "esp32"                     // ESP32
    case teensy40 = "teensy-40"              // Teensy 4.0
    case custom = "custom"
}

/// Transport layer types for board communication
public enum TransportType: String, Codable, CaseIterable {
    case serial = "serial"                   // Serial/USB connection
    case native = "native"                   // Native/Direct connection
    case network = "network"                 // Network-based (TCP/UDP)
}

// MARK: - Pin Aliasing

/// Represents a named pin on a hardware board
public struct PinAlias: Codable, Identifiable {
    public let id: UUID
    public let alias: String                 // e.g., "red_led"
    public let physicalPin: Int              // e.g., 13
    public let description: String
    public let pinType: String               // e.g., "digital", "analog", "pwm"

    public init(id: UUID = UUID(), alias: String, physicalPin: Int,
                description: String = "", pinType: String = "digital") {
        self.id = id
        self.alias = alias
        self.physicalPin = physicalPin
        self.description = description
        self.pinType = pinType
    }
}

// MARK: - Hardware Board

/// Metadata for tracking board state
public struct HardwareBoardMetadata: Codable {
    public var created: Date
    public var modified: Date
    public var lastConnected: Date?
    public var isActive: Bool
    public var tags: [String]
    public var notes: String

    public init(created: Date = Date(), modified: Date = Date(),
                lastConnected: Date? = nil, isActive: Bool = true,
                tags: [String] = [], notes: String = "") {
        self.created = created
        self.modified = modified
        self.lastConnected = lastConnected
        self.isActive = isActive
        self.tags = tags
        self.notes = notes
    }
}

/// Represents a hardware board configuration
public struct HardwareBoard: Codable, Identifiable {
    public let id: UUID
    public var name: String
    public let boardType: BoardType
    public var description: String
    public var serialPort: String?           // e.g., "/dev/ttyUSB0" or "COM3"
    public var baudRate: Int                 // e.g., 9600, 115200
    public var transportType: TransportType
    public var pinAliases: [PinAlias]
    public var datasheetURL: String?         // URL to board documentation
    public var metadata: HardwareBoardMetadata

    public init(id: UUID = UUID(), name: String, boardType: BoardType,
                description: String = "", serialPort: String? = nil,
                baudRate: Int = 9600, transportType: TransportType = .serial,
                pinAliases: [PinAlias] = [], datasheetURL: String? = nil,
                metadata: HardwareBoardMetadata = HardwareBoardMetadata()) {
        self.id = id
        self.name = name
        self.boardType = boardType
        self.description = description
        self.serialPort = serialPort
        self.baudRate = baudRate
        self.transportType = transportType
        self.pinAliases = pinAliases
        self.datasheetURL = datasheetURL
        self.metadata = metadata
    }
}

// MARK: - Peripherals

/// Represents a pin within a peripheral
public struct PeripheralPin: Codable, Identifiable {
    public let id: UUID
    public let pinAlias: String              // Reference to PinAlias
    public var mode: String                  // "input", "output", "pwm", "analog"
    public var currentValue: String?         // Current pin state

    public init(id: UUID = UUID(), pinAlias: String, mode: String = "output",
                currentValue: String? = nil) {
        self.id = id
        self.pinAlias = pinAlias
        self.mode = mode
        self.currentValue = currentValue
    }
}

/// Metadata for peripherals
public struct PeripheralMetadata: Codable {
    public var created: Date
    public var modified: Date
    public var description: String
    public var tags: [String]

    public init(created: Date = Date(), modified: Date = Date(),
                description: String = "", tags: [String] = []) {
        self.created = created
        self.modified = modified
        self.description = description
        self.tags = tags
    }
}

/// Represents a peripheral device (sensor, actuator, etc.)
public struct Peripheral: Codable, Identifiable {
    public let id: UUID
    public var name: String
    public let boardId: UUID
    public var type: String                  // "led", "button", "sensor", "motor"
    public var pins: [PeripheralPin]
    public var metadata: PeripheralMetadata

    public init(id: UUID = UUID(), name: String, boardId: UUID,
                type: String, pins: [PeripheralPin] = [],
                metadata: PeripheralMetadata = PeripheralMetadata()) {
        self.id = id
        self.name = name
        self.boardId = boardId
        self.type = type
        self.pins = pins
        self.metadata = metadata
    }
}

// MARK: - Errors

/// Errors that can occur during hardware operations
public enum HardwareError: Error, LocalizedError {
    case boardNotFound
    case boardAlreadyExists(String)
    case invalidBoardType
    case invalidSerialPort
    case connectionFailed(String)
    case peripheralNotFound
    case invalidPinConfiguration

    public var errorDescription: String? {
        switch self {
        case .boardNotFound:
            return "Hardware board not found"
        case .boardAlreadyExists(let name):
            return "Board named '\(name)' already exists"
        case .invalidBoardType:
            return "Invalid board type"
        case .invalidSerialPort:
            return "Invalid serial port configuration"
        case .connectionFailed(let msg):
            return "Connection failed: \(msg)"
        case .peripheralNotFound:
            return "Peripheral not found"
        case .invalidPinConfiguration:
            return "Invalid pin configuration"
        }
    }
}
