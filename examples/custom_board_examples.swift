import Foundation
import WritersApp

// MARK: - Custom Board Examples
// Complete working examples of custom board creation and pin configuration

// MARK: - Example 1: Smart Plant Monitor

func createSmartPlantMonitor(app: WritersApp) throws {
    let plantMonitorPins: [PinAlias] = [
        // Analog sensors
        PinAlias(
            alias: "soil_moisture_sensor",
            physicalPin: 0,
            description: "Capacitive soil moisture sensor on A0 (0-1023 range)",
            pinType: "analog"
        ),
        PinAlias(
            alias: "temp_humidity_sensor",
            physicalPin: 1,
            description: "DHT22 temperature/humidity sensor on A1",
            pinType: "analog"
        ),

        // Control outputs
        PinAlias(
            alias: "water_pump",
            physicalPin: 3,
            description: "Water pump relay with PWM speed control",
            pinType: "pwm"
        ),
        PinAlias(
            alias: "grow_light",
            physicalPin: 5,
            description: "LED grow light with PWM brightness control",
            pinType: "pwm"
        ),

        // Status indicators
        PinAlias(
            alias: "status_led",
            physicalPin: 13,
            description: "Green LED - system active",
            pinType: "digital"
        ),
        PinAlias(
            alias: "warning_led",
            physicalPin: 12,
            description: "Yellow LED - warning condition",
            pinType: "digital"
        ),
        PinAlias(
            alias: "error_led",
            physicalPin: 11,
            description: "Red LED - error condition",
            pinType: "digital"
        ),

        // User input
        PinAlias(
            alias: "manual_water_button",
            physicalPin: 2,
            description: "Push button for manual watering",
            pinType: "digital"
        ),
        PinAlias(
            alias: "light_override",
            physicalPin: 4,
            description: "Toggle button for grow light override",
            pinType: "digital"
        )
    ]

    let smartPlantBoard = HardwareBoard(
        name: "Smart Plant Monitor",
        boardType: .custom,
        description: """
        Automated plant care system with soil moisture monitoring,
        temperature/humidity sensing, automatic watering, and LED grow light control.
        Includes manual override buttons and status LED indicators.
        """,
        serialPort: "/dev/ttyUSB0",
        baudRate: 9600,
        transportType: .serial,
        pinAliases: plantMonitorPins,
        datasheetURL: "https://example.com/plant-monitor-schematic.pdf",
        metadata: HardwareBoardMetadata(
            tags: ["agriculture", "IoT", "automation", "plant-care"],
            notes: """
            Deployed in home greenhouse.
            Calibrate soil moisture sensor: dry=~300, wet=~700
            Grow light timer: 12 hours on, 12 hours off
            Water threshold: activate at moisture < 400
            """
        )
    )

    try app.hardwareManager.createBoard(smartPlantBoard)
    print("✓ Smart Plant Monitor board created")
    print("  Board ID: \(smartPlantBoard.id.uuidString)")
}

// MARK: - Example 2: Robot Car Platform

func createRobotCarPlatform(app: WritersApp) throws {
    let robotCarPins: [PinAlias] = [
        // Motor control - Left wheel
        PinAlias(
            alias: "left_motor_fwd",
            physicalPin: 5,
            description: "Left wheel forward (H-bridge IN1)",
            pinType: "pwm"
        ),
        PinAlias(
            alias: "left_motor_rev",
            physicalPin: 6,
            description: "Left wheel reverse (H-bridge IN2)",
            pinType: "pwm"
        ),

        // Motor control - Right wheel
        PinAlias(
            alias: "right_motor_fwd",
            physicalPin: 9,
            description: "Right wheel forward (H-bridge IN3)",
            pinType: "pwm"
        ),
        PinAlias(
            alias: "right_motor_rev",
            physicalPin: 10,
            description: "Right wheel reverse (H-bridge IN4)",
            pinType: "pwm"
        ),

        // Sensors
        PinAlias(
            alias: "motion_sensor",
            physicalPin: 7,
            description: "PIR motion detection sensor",
            pinType: "digital"
        ),
        PinAlias(
            alias: "distance_sensor",
            physicalPin: 8,
            description: "Ultrasonic distance sensor trigger",
            pinType: "digital"
        ),
        PinAlias(
            alias: "distance_echo",
            physicalPin: 2,
            description: "Ultrasonic distance sensor echo",
            pinType: "digital"
        ),

        // Status and control
        PinAlias(
            alias: "front_led",
            physicalPin: 13,
            description: "Front white LED headlight",
            pinType: "digital"
        ),
        PinAlias(
            alias: "back_led",
            physicalPin: 12,
            description: "Back red LED tail light",
            pinType: "digital"
        ),
        PinAlias(
            alias: "buzzer",
            physicalPin: 3,
            description: "Audio feedback buzzer (PWM tone control)",
            pinType: "pwm"
        ),

        // Battery monitoring
        PinAlias(
            alias: "battery_voltage",
            physicalPin: 0,
            description: "Battery voltage monitor on A0",
            pinType: "analog"
        )
    ]

    let robotCarBoard = HardwareBoard(
        name: "Autonomous Robot Car",
        boardType: .custom,
        description: """
        4-wheel robot platform with obstacle avoidance, motion detection,
        and autonomous navigation capabilities. Includes dual motor control,
        ultrasonic distance sensing, and status indicators.
        """,
        serialPort: "/dev/ttyUSB0",
        baudRate: 9600,
        transportType: .serial,
        pinAliases: robotCarPins,
        metadata: HardwareBoardMetadata(
            tags: ["robotics", "autonomous", "mobile", "obstacle-avoidance"],
            notes: """
            Robot chassis: 4WD with 1:48 gear ratio motors
            Motor specs: 3-6V, ~200 RPM no-load
            H-bridge: L298N dual motor driver
            Power: 4x AA battery holder (6V)
            Wheel diameter: 65mm
            """
        )
    )

    try app.hardwareManager.createBoard(robotCarBoard)
    print("✓ Robot Car platform created")
    print("  Board ID: \(robotCarBoard.id.uuidString)")
}

// MARK: - Example 3: Weather Station with Cloud Sync

func createWeatherStation(app: WritersApp) throws {
    let weatherStationPins: [PinAlias] = [
        // Environmental sensors
        PinAlias(
            alias: "dht22_signal",
            physicalPin: 2,
            description: "DHT22 temperature/humidity sensor data pin",
            pinType: "digital"
        ),
        PinAlias(
            alias: "pressure_sensor",
            physicalPin: 3,
            description: "BMP280 barometric pressure sensor (I2C)",
            pinType: "digital"
        ),
        PinAlias(
            alias: "light_sensor",
            physicalPin: 0,
            description: "BH1750 ambient light sensor (I2C)",
            pinType: "analog"
        ),
        PinAlias(
            alias: "uv_sensor",
            physicalPin: 1,
            description: "ML8511 UV intensity sensor",
            pinType: "analog"
        ),

        // I2C communication
        PinAlias(
            alias: "i2c_sda",
            physicalPin: 20,
            description: "I2C Serial Data line for sensors",
            pinType: "digital"
        ),
        PinAlias(
            alias: "i2c_scl",
            physicalPin: 21,
            description: "I2C Serial Clock line",
            pinType: "digital"
        ),

        // Data logging
        PinAlias(
            alias: "sd_cs",
            physicalPin: 10,
            description: "SD card chip select (SPI)",
            pinType: "digital"
        ),
        PinAlias(
            alias: "sd_clk",
            physicalPin: 13,
            description: "SD card clock (SPI)",
            pinType: "digital"
        ),
        PinAlias(
            alias: "sd_mosi",
            physicalPin: 11,
            description: "SD card MOSI (SPI)",
            pinType: "digital"
        ),
        PinAlias(
            alias: "sd_miso",
            physicalPin: 12,
            description: "SD card MISO (SPI)",
            pinType: "digital"
        ),

        // WiFi module
        PinAlias(
            alias: "wifi_rx",
            physicalPin: 0,
            description: "ESP8266 WiFi module RX",
            pinType: "digital"
        ),
        PinAlias(
            alias: "wifi_tx",
            physicalPin: 1,
            description: "ESP8266 WiFi module TX",
            pinType: "digital"
        ),

        // Status
        PinAlias(
            alias: "status_led",
            physicalPin: 13,
            description: "System status indicator",
            pinType: "digital"
        ),
        PinAlias(
            alias: "error_led",
            physicalPin: 12,
            description: "Error condition indicator",
            pinType: "digital"
        )
    ]

    let weatherStation = HardwareBoard(
        name: "Advanced Weather Station",
        boardType: .custom,
        description: """
        Professional weather monitoring system with temperature, humidity,
        pressure, light level, and UV intensity sensors. Includes SD card
        data logging and WiFi cloud sync via ESP8266 module.
        """,
        serialPort: "/dev/ttyUSB0",
        baudRate: 115200,
        transportType: .serial,
        pinAliases: weatherStationPins,
        datasheetURL: "https://example.com/weather-station-schematic.pdf",
        metadata: HardwareBoardMetadata(
            tags: ["weather", "environmental-monitoring", "IoT", "data-logging"],
            notes: """
            Mounted on roof of house (outdoor enclosure)
            Sensors calibrated monthly
            Cloud sync every 30 minutes to weather.example.com
            Latitude: 40.7128, Longitude: -74.0060
            Elevation: 10m above sea level
            """
        )
    )

    try app.hardwareManager.createBoard(weatherStation)
    print("✓ Weather Station created")
    print("  Board ID: \(weatherStation.id.uuidString)")
}

// MARK: - Example 4: Smart Home Control Hub

func createSmartHomeHub(app: WritersApp) throws {
    let smartHomeHubPins: [PinAlias] = [
        // Lighting control (PWM for dimmable lights)
        PinAlias(
            alias: "living_room_light",
            physicalPin: 3,
            description: "Living room dimmable light (PWM 0-255)",
            pinType: "pwm"
        ),
        PinAlias(
            alias: "bedroom_light",
            physicalPin: 5,
            description: "Bedroom dimmable light (PWM)",
            pinType: "pwm"
        ),
        PinAlias(
            alias: "kitchen_light",
            physicalPin: 6,
            description: "Kitchen dimmable light (PWM)",
            pinType: "pwm"
        ),

        // Switch inputs
        PinAlias(
            alias: "wall_switch_1",
            physicalPin: 2,
            description: "Wall switch for living room",
            pinType: "digital"
        ),
        PinAlias(
            alias: "wall_switch_2",
            physicalPin: 4,
            description: "Wall switch for bedroom",
            pinType: "digital"
        ),
        PinAlias(
            alias: "wall_switch_3",
            physicalPin: 7,
            description: "Wall switch for kitchen",
            pinType: "digital"
        ),

        // Temperature control
        PinAlias(
            alias: "thermostat",
            physicalPin: 8,
            description: "Thermostat control relay",
            pinType: "digital"
        ),
        PinAlias(
            alias: "temp_sensor",
            physicalPin: 0,
            description: "Indoor temperature sensor",
            pinType: "analog"
        ),

        // Security
        PinAlias(
            alias: "door_lock",
            physicalPin: 9,
            description: "Front door electric lock control",
            pinType: "digital"
        ),
        PinAlias(
            alias: "door_sensor",
            physicalPin: 10,
            description: "Door open/close sensor",
            pinType: "digital"
        ),

        // Alarms
        PinAlias(
            alias: "motion_alarm",
            physicalPin: 11,
            description: "Motion detector alarm trigger",
            pinType: "digital"
        ),

        // Communication (I2C)
        PinAlias(
            alias: "i2c_sda",
            physicalPin: 20,
            description: "I2C for remote modules",
            pinType: "digital"
        ),
        PinAlias(
            alias: "i2c_scl",
            physicalPin: 21,
            description: "I2C clock",
            pinType: "digital"
        )
    ]

    let smartHomeHub = HardwareBoard(
        name: "Smart Home Control Hub",
        boardType: .custom,
        description: """
        Central home automation hub with lighting control, temperature
        management, security features, and wall switch integration.
        Supports multiple rooms and automated scheduling.
        """,
        serialPort: "/dev/ttyUSB0",
        baudRate: 9600,
        transportType: .serial,
        pinAliases: smartHomeHubPins,
        metadata: HardwareBoardMetadata(
            tags: ["smart-home", "automation", "home-control"],
            notes: """
            Installed in basement electrical panel
            Connected to: 3 light circuits, thermostat, door lock, sensors
            Automation: Sunset dimming, away mode, vacation mode
            Backup power: UPS with 4-hour runtime
            """
        )
    )

    try app.hardwareManager.createBoard(smartHomeHub)
    print("✓ Smart Home Hub created")
    print("  Board ID: \(smartHomeHub.id.uuidString)")
}

// MARK: - Main: Create all example boards

func createAllExampleBoards() {
    let app = WritersApp()

    print("Creating custom hardware board examples...\n")

    do {
        try createSmartPlantMonitor(app: app)
        try createRobotCarPlatform(app: app)
        try createWeatherStation(app: app)
        try createSmartHomeHub(app: app)

        print("\n✓ All example boards created successfully!")
        print("\nYou can now:")
        print("1. View boards with option 81: List Hardware Boards")
        print("2. View details with option 82: View Board Details")
        print("3. Add pins with option 84: Manage Pin Aliases")
        print("4. Use these as templates for your own projects")

    } catch {
        print("✗ Error creating boards: \(error.localizedDescription)")
    }
}

// Run examples
// createAllExampleBoards()
