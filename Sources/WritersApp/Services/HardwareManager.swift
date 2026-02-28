import Foundation

/// Manages hardware board configurations and peripherals
public class HardwareManager {
    private var boards: [UUID: HardwareBoard]
    private var peripherals: [UUID: Peripheral]
    private var activeConnections: [UUID: String]  // boardId -> connection status

    public init() {
        self.boards = [:]
        self.peripherals = [:]
        self.activeConnections = [:]
        loadDefaultBoards()
    }

    // MARK: - Board Management

    /// Creates a new hardware board
    public func createBoard(_ board: HardwareBoard) throws {
        // Check for duplicate names
        if boards.values.contains(where: { $0.name.lowercased() == board.name.lowercased() }) {
            throw HardwareError.boardAlreadyExists(board.name)
        }
        boards[board.id] = board
    }

    /// Retrieves a board by ID
    public func getBoard(id: UUID) -> HardwareBoard? {
        return boards[id]
    }

    /// Retrieves all boards
    public func getAllBoards() -> [HardwareBoard] {
        return Array(boards.values)
            .sorted { $0.metadata.created > $1.metadata.created }
    }

    /// Retrieves boards by type
    public func getBoards(byType type: BoardType) -> [HardwareBoard] {
        return boards.values.filter { $0.boardType == type }
            .sorted { $0.metadata.created > $1.metadata.created }
    }

    /// Searches boards by name or description
    public func searchBoards(query: String) -> [HardwareBoard] {
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return getAllBoards()
        }

        return boards.values.filter { board in
            board.name.localizedCaseInsensitiveContains(query) ||
            board.description.localizedCaseInsensitiveContains(query)
        }.sorted { $0.metadata.created > $1.metadata.created }
    }

    /// Updates an existing board
    public func updateBoard(_ board: HardwareBoard) {
        var updated = board
        updated.metadata.modified = Date()
        boards[board.id] = updated
    }

    /// Deletes a board and all its peripherals
    public func deleteBoard(id: UUID) throws {
        // Remove all peripherals on this board
        let orphanedPeripheralIds = peripherals.values
            .filter { $0.boardId == id }
            .map { $0.id }
        for peripheralId in orphanedPeripheralIds {
            peripherals.removeValue(forKey: peripheralId)
        }

        boards.removeValue(forKey: id)
        activeConnections.removeValue(forKey: id)
    }

    /// Marks a board as connected
    public func markBoardConnected(id: UUID) {
        guard var board = boards[id] else { return }
        board.metadata.lastConnected = Date()
        board.metadata.isActive = true
        boards[id] = board
        activeConnections[id] = "connected"
    }

    /// Marks a board as disconnected
    public func markBoardDisconnected(id: UUID) {
        guard var board = boards[id] else { return }
        board.metadata.isActive = false
        boards[id] = board
        activeConnections.removeValue(forKey: id)
    }

    /// Gets connection status
    public func getConnectionStatus(boardId: UUID) -> String? {
        return activeConnections[boardId]
    }

    // MARK: - Pin Alias Management

    /// Adds a pin alias to a board
    public func addPinAlias(to boardId: UUID, alias: PinAlias) throws {
        guard var board = boards[boardId] else {
            throw HardwareError.boardNotFound
        }

        // Check for duplicate alias names
        if board.pinAliases.contains(where: { $0.alias == alias.alias }) {
            throw HardwareError.invalidPinConfiguration
        }

        board.pinAliases.append(alias)
        boards[boardId] = board
    }

    /// Retrieves a pin alias by name
    public func getPinAlias(boardId: UUID, aliasName: String) -> PinAlias? {
        guard let board = boards[boardId] else { return nil }
        return board.pinAliases.first { $0.alias == aliasName }
    }

    /// Removes a pin alias from a board
    public func removePinAlias(from boardId: UUID, aliasId: UUID) throws {
        guard var board = boards[boardId] else {
            throw HardwareError.boardNotFound
        }

        board.pinAliases.removeAll { $0.id == aliasId }
        boards[boardId] = board
    }

    // MARK: - Peripheral Management

    /// Creates a new peripheral
    public func createPeripheral(_ peripheral: Peripheral) throws {
        // Validate board exists
        guard boards[peripheral.boardId] != nil else {
            throw HardwareError.boardNotFound
        }

        peripherals[peripheral.id] = peripheral
    }

    /// Retrieves a peripheral by ID
    public func getPeripheral(id: UUID) -> Peripheral? {
        return peripherals[id]
    }

    /// Retrieves peripherals for a board
    public func getPeripherals(forBoard boardId: UUID) -> [Peripheral] {
        return peripherals.values.filter { $0.boardId == boardId }
            .sorted { $0.metadata.created > $1.metadata.created }
    }

    /// Retrieves peripherals by type
    public func getPeripherals(byType type: String) -> [Peripheral] {
        return peripherals.values.filter { $0.type == type }
            .sorted { $0.metadata.created > $1.metadata.created }
    }

    /// Updates a peripheral
    public func updatePeripheral(_ peripheral: Peripheral) {
        var updated = peripheral
        updated.metadata.modified = Date()
        peripherals[peripheral.id] = updated
    }

    /// Deletes a peripheral
    public func deletePeripheral(id: UUID) {
        peripherals.removeValue(forKey: id)
    }

    // MARK: - Statistics

    /// Gets board statistics
    public func getBoardStatistics() -> (totalBoards: Int, byType: [BoardType: Int], activeCount: Int) {
        let totalBoards = boards.count
        let byType = Dictionary(grouping: boards.values, by: { $0.boardType })
            .mapValues { $0.count }
        let activeCount = activeConnections.count
        return (totalBoards, byType, activeCount)
    }

    /// Gets all active boards
    public func getActiveBoards() -> [HardwareBoard] {
        return boards.values.filter { $0.metadata.isActive }
            .sorted { $0.metadata.created > $1.metadata.created }
    }

    // MARK: - Default Boards

    private func loadDefaultBoards() {
        // Arduino Uno default configuration
        let arduinoUno = HardwareBoard(
            name: "Arduino Uno Template",
            boardType: .arduinoUno,
            description: "ATmega328P microcontroller board with 14 digital pins",
            serialPort: "/dev/ttyUSB0",
            baudRate: 9600,
            transportType: .serial,
            pinAliases: [
                PinAlias(alias: "red_led", physicalPin: 13, description: "LED pin", pinType: "digital"),
                PinAlias(alias: "button", physicalPin: 2, description: "Button pin", pinType: "digital"),
                PinAlias(alias: "analog_sensor", physicalPin: 0, description: "Analog input", pinType: "analog"),
                PinAlias(alias: "pwm_pin", physicalPin: 3, description: "PWM output", pinType: "pwm")
            ],
            datasheetURL: "https://docs.arduino.cc/hardware/uno"
        )
        boards[arduinoUno.id] = arduinoUno

        // Nucleo F401RE default configuration
        let nucleoF401RE = HardwareBoard(
            name: "Nucleo F401RE Template",
            boardType: .nucleoF401RE,
            description: "STM32F401RE Arm Cortex-M4 microcontroller",
            serialPort: "/dev/ttyACM0",
            baudRate: 115200,
            transportType: .serial,
            pinAliases: [
                PinAlias(alias: "user_led", physicalPin: 5, description: "Green LED", pinType: "digital"),
                PinAlias(alias: "user_button", physicalPin: 13, description: "User button", pinType: "digital"),
                PinAlias(alias: "uart_tx", physicalPin: 1, description: "UART TX", pinType: "digital"),
                PinAlias(alias: "uart_rx", physicalPin: 0, description: "UART RX", pinType: "digital")
            ],
            datasheetURL: "https://www.st.com/en/evaluation-tools/nucleo-f401re.html"
        )
        boards[nucleoF401RE.id] = nucleoF401RE
    }
}
