import Foundation
import WritersApp

// MARK: - Custom Board Examples
// Complete working examples of custom board creation and pin configuration

// MARK: - Example 1: Smart Plant Monitor

func createSmartPlantMonitor(app: WritersApp) throws {
    let plantMonitorPins: [PinAlias] = [
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
        PinAlias(
            alias: "manual_water_button",
            physicalPin: 2,
            description: "Push button for manual watering",
            pinType: "digital"
        )
    ]

    let smartPlantBoard = HardwareBoard(
        name: "Smart Plant Monitor",
        boardType: .custom,
        description: """
        Automated plant care system with soil moisture monitoring,
        temperature/humidity sensing, automatic watering, and LED grow light control.
        """,
        serialPort: "/dev/ttyUSB0",
        baudRate: 9600,
        transportType: .serial,
        pinAliases: plantMonitorPins,
        metadata: HardwareBoardMetadata(
            tags: ["agriculture", "IoT", "automation", "plant-care"],
            notes: "Deployed in home greenhouse. Calibrate soil sensor monthly."
        )
    )

    try app.hardwareManager.createBoard(smartPlantBoard)
    print("✓ Smart Plant Monitor board created")
    print("  Board ID: \(smartPlantBoard.id.uuidString)")
}

// MARK: - Example 2: Smart Home Control Hub

func createSmartHomeHub(app: WritersApp) throws {
    let smartHomeHubPins: [PinAlias] = [
        PinAlias(alias: "living_room_light", physicalPin: 3,
                 description: "Living room dimmable light (PWM 0-255)", pinType: "pwm"),
        PinAlias(alias: "bedroom_light", physicalPin: 5,
                 description: "Bedroom dimmable light (PWM)", pinType: "pwm"),
        PinAlias(alias: "kitchen_light", physicalPin: 6,
                 description: "Kitchen dimmable light (PWM)", pinType: "pwm"),
        PinAlias(alias: "wall_switch_1", physicalPin: 2,
                 description: "Wall switch for living room", pinType: "digital"),
        PinAlias(alias: "wall_switch_2", physicalPin: 4,
                 description: "Wall switch for bedroom", pinType: "digital"),
        PinAlias(alias: "thermostat", physicalPin: 8,
                 description: "Thermostat control relay", pinType: "digital"),
        PinAlias(alias: "temp_sensor", physicalPin: 0,
                 description: "Indoor temperature sensor", pinType: "analog"),
        PinAlias(alias: "door_lock", physicalPin: 9,
                 description: "Front door electric lock control", pinType: "digital"),
        PinAlias(alias: "door_sensor", physicalPin: 10,
                 description: "Door open/close sensor", pinType: "digital"),
        PinAlias(alias: "i2c_sda", physicalPin: 20,
                 description: "I2C for remote modules", pinType: "digital"),
        PinAlias(alias: "i2c_scl", physicalPin: 21,
                 description: "I2C clock", pinType: "digital")
    ]

    let smartHomeHub = HardwareBoard(
        name: "Smart Home Control Hub",
        boardType: .custom,
        description: """
        Central home automation hub with lighting control, temperature
        management, security features, and wall switch integration.
        """,
        serialPort: "/dev/ttyUSB0",
        baudRate: 9600,
        transportType: .serial,
        pinAliases: smartHomeHubPins,
        metadata: HardwareBoardMetadata(
            tags: ["smart-home", "automation", "home-control"],
            notes: "Installed in basement electrical panel"
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
