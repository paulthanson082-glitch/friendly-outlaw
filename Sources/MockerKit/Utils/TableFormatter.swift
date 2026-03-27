import Foundation

// MARK: - TableFormatter

public enum TableFormatter {

    // MARK: - PS (container list)

    public static func formatPS(
        _ containers: [ContainerInfo],
        all: Bool,
        quiet: Bool,
        noTrunc: Bool
    ) -> String {
        if quiet {
            return containers
                .map { noTrunc ? $0.id : $0.shortId }
                .joined(separator: "\n")
        }

        let header = "CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES"
        guard !containers.isEmpty else { return header }

        var rows: [String] = [header]
        for c in containers {
            let cid     = noTrunc ? c.id : c.shortId
            let image   = c.image
            let cmd     = c.command.isEmpty ? "" : "\"\(c.command)\""
            let created = relativeTime(c.createdAt)
            let status  = c.statusDescription
            let ports   = c.ports.map { $0.description }.joined(separator: ", ")
            let name    = c.name
            rows.append("\(cid)   \(image)   \(cmd)   \(created)   \(status)   \(ports)   \(name)")
        }
        return rows.joined(separator: "\n")
    }

    // MARK: - Images

    public static func formatImages(
        _ images: [ImageInfo],
        quiet: Bool,
        noTrunc: Bool
    ) -> String {
        if quiet {
            return images
                .map { noTrunc ? $0.id : String($0.id.prefix(12)) }
                .joined(separator: "\n")
        }

        let header = "REPOSITORY   TAG       IMAGE ID      CREATED   SIZE"
        guard !images.isEmpty else { return header }

        var rows: [String] = [header]
        for img in images {
            let imgId   = noTrunc ? img.id : img.shortId
            let created = relativeTime(img.createdAt)
            let size    = formatSize(img.size)
            rows.append("\(img.repository)   \(img.tag)   \(imgId)   \(created)   \(size)")
        }
        return rows.joined(separator: "\n")
    }

    // MARK: - Networks

    public static func formatNetworks(_ networks: [NetworkInfo]) -> String {
        let header = "NETWORK ID     NAME      DRIVER    SCOPE"
        var rows: [String] = [header]
        for net in networks {
            rows.append("\(net.shortId)   \(net.name)   \(net.driver)   \(net.scope)")
        }
        return rows.joined(separator: "\n")
    }

    // MARK: - Volumes

    public static func formatVolumes(_ volumes: [VolumeInfo]) -> String {
        let header = "DRIVER    VOLUME NAME"
        var rows: [String] = [header]
        for vol in volumes {
            rows.append("\(vol.driver)   \(vol.name)")
        }
        return rows.joined(separator: "\n")
    }

    // MARK: - Relative time

    public static func relativeTime(_ date: Date) -> String {
        let elapsed = Int(Date().timeIntervalSince(date))
        let abs = Swift.abs(elapsed)
        if abs < 60 {
            return "\(abs) seconds ago"
        } else if abs < 3600 {
            let m = abs / 60
            return "\(m) minute\(m == 1 ? "" : "s") ago"
        } else if abs < 86400 {
            let h = abs / 3600
            return "\(h) hour\(h == 1 ? "" : "s") ago"
        } else {
            let d = abs / 86400
            return "\(d) day\(d == 1 ? "" : "s") ago"
        }
    }

    // MARK: - Helpers

    private static func formatSize(_ bytes: Int64) -> String {
        let kb = Double(bytes) / 1_000
        let mb = kb / 1_000
        let gb = mb / 1_000
        if gb >= 1 { return String(format: "%.2f GB", gb) }
        if mb >= 1 { return String(format: "%.2f MB", mb) }
        if kb >= 1 { return String(format: "%.2f kB", kb) }
        return "\(bytes) B"
    }
}
