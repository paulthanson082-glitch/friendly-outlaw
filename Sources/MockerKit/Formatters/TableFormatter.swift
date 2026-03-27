import Foundation

// MARK: - TableFormatter

public enum TableFormatter {

    // MARK: - Container PS

    public static func formatPS(_ containers: [ContainerInfo], all: Bool, quiet: Bool, noTrunc: Bool) -> String {
        if quiet {
            return containers.map { noTrunc ? $0.id : $0.shortId }.joined(separator: "\n")
        }

        let header = ["CONTAINER ID", "IMAGE", "COMMAND", "CREATED", "STATUS", "PORTS", "NAMES"]
        var rows: [[String]] = []
        for c in containers {
            let id = noTrunc ? c.id : c.shortId
            let cmd = truncate(c.command.isEmpty ? "\"\"" : "\"\(c.command)\"", to: noTrunc ? .max : 20)
            let created = relativeTime(c.createdAt)
            let status = c.statusDescription
            let ports = c.ports.map { $0.description }.joined(separator: ", ")
            rows.append([id, c.image, cmd, created, status, ports, c.name])
        }
        return formatTable(header: header, rows: rows)
    }

    // MARK: - Images

    public static func formatImages(_ images: [ImageInfo], quiet: Bool, noTrunc: Bool) -> String {
        if quiet {
            return images.map { noTrunc ? $0.id : String($0.id.prefix(12)) }.joined(separator: "\n")
        }
        let header = ["REPOSITORY", "TAG", "IMAGE ID", "CREATED", "SIZE"]
        var rows: [[String]] = []
        for img in images {
            let id = noTrunc ? img.id : String(img.id.prefix(12))
            let created = relativeTime(img.createdAt)
            rows.append([img.repository, img.tag, id, created, img.sizeDescription])
        }
        return formatTable(header: header, rows: rows)
    }

    // MARK: - Networks

    public static func formatNetworks(_ networks: [NetworkInfo]) -> String {
        let header = ["NETWORK ID", "NAME", "DRIVER", "SCOPE"]
        let rows = networks.map { net -> [String] in
            [net.shortId, net.name, net.driver, net.scope]
        }
        return formatTable(header: header, rows: rows)
    }

    // MARK: - Volumes

    public static func formatVolumes(_ volumes: [VolumeInfo]) -> String {
        let header = ["DRIVER", "VOLUME NAME"]
        let rows = volumes.map { vol -> [String] in [vol.driver, vol.name] }
        return formatTable(header: header, rows: rows)
    }

    // MARK: - Stats

    public static func formatStats(_ stats: [ContainerStats], noStream: Bool) -> String {
        let header = ["CONTAINER ID", "NAME", "CPU %", "MEM USAGE / LIMIT", "MEM %", "NET I/O", "BLOCK I/O", "PIDS"]
        var rows: [[String]] = []
        for s in stats {
            let cpu = String(format: "%.2f%%", s.cpuPercent)
            let mem = "\(formatBytes(s.memUsage)) / \(formatBytes(s.memLimit))"
            let memPct = String(format: "%.2f%%", s.memPercent)
            let net = "\(formatBytes(s.networkRx)) / \(formatBytes(s.networkTx))"
            let block = "\(formatBytes(s.blockRead)) / \(formatBytes(s.blockWrite))"
            rows.append([String(s.containerId.prefix(12)), s.name, cpu, mem, memPct, net, block, "\(s.pids)"])
        }
        return formatTable(header: header, rows: rows)
    }

    // MARK: - Compose PS

    public static func formatComposePS(_ containers: [ContainerInfo], projectName: String) -> String {
        let header = ["NAME", "IMAGE", "COMMAND", "SERVICE", "CREATED", "STATUS", "PORTS"]
        var rows: [[String]] = []
        for c in containers {
            let service = c.labels["com.docker.compose.service"] ?? ""
            let created = relativeTime(c.createdAt)
            let ports = c.ports.map { $0.description }.joined(separator: ", ")
            rows.append([c.name, c.image, c.command, service, created, c.statusDescription, ports])
        }
        return formatTable(header: header, rows: rows)
    }

    // MARK: - Generic table

    public static func formatTable(header: [String], rows: [[String]]) -> String {
        var allRows = [header] + rows
        let colCount = header.count
        var widths = [Int](repeating: 0, count: colCount)
        for row in allRows {
            for (i, cell) in row.prefix(colCount).enumerated() {
                widths[i] = max(widths[i], cell.count)
            }
        }

        var lines: [String] = []
        for row in allRows {
            var cells: [String] = []
            for (i, cell) in row.prefix(colCount).enumerated() {
                let padding = widths[i] - cell.count
                cells.append(cell + String(repeating: " ", count: max(padding, 0)))
            }
            lines.append(cells.joined(separator: "   "))
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Helpers

    private static func truncate(_ s: String, to length: Int) -> String {
        guard s.count > length else { return s }
        return String(s.prefix(length - 3)) + "..."
    }

    public static func relativeTime(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "\(seconds) seconds ago" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes) minutes ago" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours) hours ago" }
        let days = hours / 24
        if days < 7 { return "\(days) days ago" }
        let weeks = days / 7
        if weeks < 4 { return "\(weeks) weeks ago" }
        let months = days / 30
        if months < 12 { return "\(months) months ago" }
        return "\(months / 12) years ago"
    }

    private static func formatBytes(_ bytes: UInt64) -> String {
        if bytes == 0 { return "0B" }
        let kb = Double(bytes) / 1024
        let mb = kb / 1024
        let gb = mb / 1024
        if gb >= 1 { return String(format: "%.2fGB", gb) }
        if mb >= 1 { return String(format: "%.2fMB", mb) }
        if kb >= 1 { return String(format: "%.2fkB", kb) }
        return "\(bytes)B"
    }
}
