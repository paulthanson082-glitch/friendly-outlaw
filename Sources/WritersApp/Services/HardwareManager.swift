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
            description: "ATmega328P microcontroller board with 14 digital pins and 6 analog inputs",
            serialPort: "/dev/ttyUSB0",
            baudRate: 9600,
            transportType: .serial,
            pinAliases: [
                PinAlias(alias: "red_led", physicalPin: 13, description: "LED pin", pinType: "digital"),
                PinAlias(alias: "button", physicalPin: 2, description: "Button pin", pinType: "digital"),
                PinAlias(alias: "green_led", physicalPin: 12, description: "Green LED", pinType: "digital"),
                PinAlias(alias: "blue_led", physicalPin: 11, description: "Blue LED (PWM)", pinType: "pwm"),
                PinAlias(alias: "analog_sensor", physicalPin: 0, description: "Analog input A0", pinType: "analog"),
                PinAlias(alias: "temp_sensor", physicalPin: 1, description: "Temperature sensor A1", pinType: "analog"),
                PinAlias(alias: "pwm_pin", physicalPin: 3, description: "PWM output", pinType: "pwm"),
                PinAlias(alias: "motor_pin", physicalPin: 9, description: "Motor control (PWM)", pinType: "pwm")
            ],
            datasheetURL: "https://docs.arduino.cc/hardware/uno"
        )
        boards[arduinoUno.id] = arduinoUno

        // Nucleo F401RE default configuration
        let nucleoF401RE = HardwareBoard(
            name: "Nucleo F401RE Template",
            boardType: .nucleoF401RE,
            description: "STM32F401RE Arm Cortex-M4 microcontroller with 84 GPIO pins",
            serialPort: "/dev/ttyACM0",
            baudRate: 115200,
            transportType: .serial,
            pinAliases: [
                PinAlias(alias: "user_led", physicalPin: 5, description: "Green LED", pinType: "digital"),
                PinAlias(alias: "led_1", physicalPin: 6, description: "LED 1", pinType: "digital"),
                PinAlias(alias: "led_2", physicalPin: 7, description: "LED 2", pinType: "digital"),
                PinAlias(alias: "user_button", physicalPin: 13, description: "User button", pinType: "digital"),
                PinAlias(alias: "uart_tx", physicalPin: 1, description: "UART TX", pinType: "digital"),
                PinAlias(alias: "uart_rx", physicalPin: 0, description: "UART RX", pinType: "digital"),
                PinAlias(alias: "spi_clk", physicalPin: 10, description: "SPI Clock", pinType: "digital"),
                PinAlias(alias: "spi_mosi", physicalPin: 11, description: "SPI MOSI", pinType: "digital"),
                PinAlias(alias: "i2c_sda", physicalPin: 9, description: "I2C SDA", pinType: "digital"),
                PinAlias(alias: "i2c_scl", physicalPin: 8, description: "I2C SCL", pinType: "digital")
            ],
            datasheetURL: "https://www.st.com/en/evaluation-tools/nucleo-f401re.html"
        )
        boards[nucleoF401RE.id] = nucleoF401RE

        // ESP32 default configuration
        let esp32 = HardwareBoard(
            name: "ESP32 Template",
            boardType: .esp32,
            description: "ESP32 dual-core WiFi + Bluetooth microcontroller with 30 GPIO pins",
            serialPort: "/dev/ttyUSB0",
            baudRate: 115200,
            transportType: .serial,
            pinAliases: [
                PinAlias(alias: "built_in_led", physicalPin: 2, description: "Built-in LED", pinType: "digital"),
                PinAlias(alias: "gpio_4", physicalPin: 4, description: "GPIO 4", pinType: "digital"),
                PinAlias(alias: "gpio_5", physicalPin: 5, description: "GPIO 5 (SPI CLK)", pinType: "digital"),
                PinAlias(alias: "gpio_12", physicalPin: 12, description: "GPIO 12 (SPI MISO)", pinType: "digital"),
                PinAlias(alias: "gpio_13", physicalPin: 13, description: "GPIO 13 (SPI MOSI)", pinType: "digital"),
                PinAlias(alias: "gpio_14", physicalPin: 14, description: "GPIO 14 (SPI CS)", pinType: "digital"),
                PinAlias(alias: "gpio_15", physicalPin: 15, description: "GPIO 15 (UART TX)", pinType: "digital"),
                PinAlias(alias: "gpio_16", physicalPin: 16, description: "GPIO 16 (UART RX)", pinType: "digital"),
                PinAlias(alias: "adc_pin", physicalPin: 35, description: "ADC input (VP)", pinType: "analog"),
                PinAlias(alias: "pwm_pin", physicalPin: 27, description: "PWM capable GPIO", pinType: "pwm"),
                PinAlias(alias: "i2c_sda", physicalPin: 21, description: "I2C SDA", pinType: "digital"),
                PinAlias(alias: "i2c_scl", physicalPin: 22, description: "I2C SCL", pinType: "digital")
            ],
            datasheetURL: "https://www.espressif.com/en/products/socs/esp32"
        )
        boards[esp32.id] = esp32

        // Raspberry Pi GPIO configuration
        let raspberryPi = HardwareBoard(
            name: "Raspberry Pi 4 GPIO Template",
            boardType: .rpiGPIO,
            description: "Raspberry Pi 4B with 40-pin GPIO header (BCM numbering)",
            transportType: .native,
            serialPort: "native",
            pinAliases: [
                PinAlias(alias: "led_red", physicalPin: 17, description: "Red LED GPIO17", pinType: "digital"),
                PinAlias(alias: "led_green", physicalPin: 27, description: "Green LED GPIO27", pinType: "digital"),
                PinAlias(alias: "led_blue", physicalPin: 22, description: "Blue LED GPIO22", pinType: "digital"),
                PinAlias(alias: "button_1", physicalPin: 23, description: "Button 1 GPIO23", pinType: "digital"),
                PinAlias(alias: "button_2", physicalPin: 24, description: "Button 2 GPIO24", pinType: "digital"),
                PinAlias(alias: "motor_1_fwd", physicalPin: 25, description: "Motor 1 Forward", pinType: "pwm"),
                PinAlias(alias: "motor_1_rev", physicalPin: 26, description: "Motor 1 Reverse", pinType: "pwm"),
                PinAlias(alias: "i2c_sda", physicalPin: 2, description: "I2C SDA (GPIO2)", pinType: "digital"),
                PinAlias(alias: "i2c_scl", physicalPin: 3, description: "I2C SCL (GPIO3)", pinType: "digital"),
                PinAlias(alias: "spi_clk", physicalPin: 11, description: "SPI CLK (GPIO11)", pinType: "digital"),
                PinAlias(alias: "spi_mosi", physicalPin: 10, description: "SPI MOSI (GPIO10)", pinType: "digital"),
                PinAlias(alias: "spi_miso", physicalPin: 9, description: "SPI MISO (GPIO9)", pinType: "digital"),
                PinAlias(alias: "uart_tx", physicalPin: 14, description: "UART TX (GPIO14)", pinType: "digital"),
                PinAlias(alias: "uart_rx", physicalPin: 15, description: "UART RX (GPIO15)", pinType: "digital")
            ],
            datasheetURL: "https://www.raspberrypi.com/products/raspberry-pi-4-model-b/specifications/"
        )
        boards[raspberryPi.id] = raspberryPi

        // Teensy 4.0 configuration
        let teensy40 = HardwareBoard(
            name: "Teensy 4.0 Template",
            boardType: .teensy40,
            description: "Teensy 4.0 with ARM Cortex-M7 600MHz processor, 32 GPIO pins",
            serialPort: "/dev/ttyACM0",
            baudRate: 115200,
            transportType: .serial,
            pinAliases: [
                PinAlias(alias: "led_pin", physicalPin: 13, description: "Built-in LED", pinType: "digital"),
                PinAlias(alias: "button", physicalPin: 0, description: "User button", pinType: "digital"),
                PinAlias(alias: "analog_1", physicalPin: 14, description: "Analog A0", pinType: "analog"),
                PinAlias(alias: "analog_2", physicalPin: 15, description: "Analog A1", pinType: "analog"),
                PinAlias(alias: "pwm_1", physicalPin: 3, description: "PWM pin 1", pinType: "pwm"),
                PinAlias(alias: "pwm_2", physicalPin: 4, description: "PWM pin 2", pinType: "pwm"),
                PinAlias(alias: "uart_tx", physicalPin: 1, description: "Serial TX", pinType: "digital"),
                PinAlias(alias: "uart_rx", physicalPin: 0, description: "Serial RX", pinType: "digital"),
                PinAlias(alias: "i2c_sda", physicalPin: 18, description: "I2C SDA", pinType: "digital"),
                PinAlias(alias: "i2c_scl", physicalPin: 19, description: "I2C SCL", pinType: "digital"),
                PinAlias(alias: "spi_clk", physicalPin: 27, description: "SPI Clock", pinType: "digital"),
                PinAlias(alias: "spi_mosi", physicalPin: 26, description: "SPI MOSI", pinType: "digital"),
                PinAlias(alias: "spi_miso", physicalPin: 1, description: "SPI MISO", pinType: "digital")
            ],
            datasheetURL: "https://www.pjrc.com/teensy/teensy40.html"
        )
        boards[teensy40.id] = teensy40
    }
}
