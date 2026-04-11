import Foundation
import os.log

/// Manages daemon/service lifecycle for WritersApp using launchd (macOS)
public class DaemonManager {
    private let config: DaemonConfig
    private let logger = OSLog(subsystem: "com.writersapp.daemon", category: "manager")

    public init(config: DaemonConfig = DaemonConfig()) {
        self.config = config
    }

    /// Starts the daemon service
    /// - Parameter port: Port for the Codex server (default 8000)
    /// - Throws: Errors starting the daemon
    public func startDaemon(port: Int = 8000) async throws {
        // Create plist content
        let plistPath = config.launchAgentPath
        let logPath = "\(config.logDirectory)/writersapp-daemon.log"

        // Ensure log directory exists
        try? FileManager.default.createDirectory(atPath: config.logDirectory, withIntermediateDirectories: true)

        // Generate plist
        let plistContent = generatePlist(port: port, logPath: logPath)

        // Write plist to disk
        let plistURL = URL(fileURLWithPath: plistPath)
        try plistContent.write(to: plistURL, atomically: true, encoding: .utf8)

        os_log("Plist created at: %@", log: logger, type: .info, plistPath)

        // Load plist with launchctl
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["load", plistPath]

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw NSError(
                domain: "DaemonManager",
                code: Int(process.terminationStatus),
                userInfo: ["error": "Failed to load daemon with launchctl"]
            )
        }

        os_log("Daemon started successfully on port %d", log: logger, type: .info, port)
    }

    /// Stops the daemon service
    /// - Throws: Errors stopping the daemon
    public func stopDaemon() async throws {
        let plistPath = config.launchAgentPath

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["unload", plistPath]

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw NSError(
                domain: "DaemonManager",
                code: Int(process.terminationStatus),
                userInfo: ["error": "Failed to unload daemon with launchctl"]
            )
        }

        // Remove plist file
        try? FileManager.default.removeItem(atPath: plistPath)

        os_log("Daemon stopped successfully", log: logger, type: .info)
    }

    /// Restarts the daemon service
    /// - Parameter port: Port for the Codex server
    /// - Throws: Errors during restart
    public func restartDaemon(port: Int = 8000) async throws {
        try await stopDaemon()

        // Give it a moment to shut down
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        try await startDaemon(port: port)

        os_log("Daemon restarted on port %d", log: logger, type: .info, port)
    }

    /// Gets daemon status
    /// - Returns: Status message
    public func getDaemonStatus() async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["list", "com.writersapp.daemon"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus == 0 {
            return "Daemon is running"
        } else {
            return "Daemon is not running"
        }
    }

    /// Tails daemon logs
    /// - Parameter lines: Number of lines to tail (default 50)
    /// - Returns: Log content
    public func tailLogs(lines: Int = 50) async throws -> String {
        let logPath = "\(config.logDirectory)/writersapp-daemon.log"

        guard FileManager.default.fileExists(atPath: logPath) else {
            return "Log file not found"
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tail")
        process.arguments = ["-n", String(lines), logPath]

        let pipe = Pipe()
        process.standardOutput = pipe

        try process.run()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }

    // MARK: - Private Helpers

    private func generatePlist(port: Int, logPath: String) -> String {
        let executablePath = "/usr/local/bin/writersapp-daemon" // Path where daemon binary would be installed
        let daemonUserName = NSUserName()

        let plist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.writersapp.daemon</string>

            <key>ProgramArguments</key>
            <array>
                <string>\(executablePath)</string>
                <string>daemon</string>
                <string>--port</string>
                <string>\(port)</string>
            </array>

            <key>RunAtLoad</key>
            <true/>

            <key>KeepAlive</key>
            <true/>

            <key>StandardOutPath</key>
            <string>\(logPath)</string>

            <key>StandardErrorPath</key>
            <string>\(logPath)</string>

            <key>WorkingDirectory</key>
            <string>\(NSHomeDirectory())</string>

            <key>UserName</key>
            <string>\(daemonUserName)</string>

            <key>ProcessType</key>
            <string>Adaptive</string>

            <key>StartInterval</key>
            <integer>60</integer>

            <key>TimeOut</key>
            <integer>30</integer>

            <key>ExitTimeOut</key>
            <integer>5</integer>
        </dict>
        </plist>
        """

        return plist
    }
}

// MARK: - Task Extension for Sleep

extension Task where Success == Never, Failure == Never {
    static func sleep(nanoseconds duration: UInt64) async throws {
        try await Task.sleep(nanoseconds: duration)
    }
}
