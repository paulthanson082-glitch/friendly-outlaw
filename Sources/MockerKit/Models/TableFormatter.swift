import Foundation

// MARK: - TableFormatter

/// Formats MockerKit model types into Docker-compatible table output.
public struct TableFormatter {

    // MARK: - Containers (ps)

    public static func formatPS(
        _ containers: [ContainerInfo],
        all: Bool,
        quiet: Bool,
        noTrunc: Bool
    ) -> String {
        let visible = all ? containers : containers.filter { $0.status == .running }
        if quiet {
            return visible.map { noTrunc ? $0.id : $0.shortId }.joined(separator: "\n")
        }
        let header = "CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES"
        let rows = visible.map { c in
            let cid  = noTrunc ? c.id : c.shortId
            let img  = pad(c.image, 10)
            let cmd  = pad(c.command.isEmpty ? "\"\"" : "\"\(c.command)\"", 10)
            let created = pad(relativeTime(c.createdAt), 10)
            let status  = pad(c.statusDescription, 10)
            let ports   = pad(c.ports.map(\.description).joined(separator: ", "), 10)
            let name    = c.name
            return "\(cid)   \(img)   \(cmd)   \(created)   \(status)   \(ports)   \(name)"
        }
        return ([header] + rows).joined(separator: "\n")
    }

    // MARK: - Images

    public static func formatImages(
        _ images: [ImageInfo],
        quiet: Bool,
        noTrunc: Bool
    ) -> String {
        if quiet {
            return images.map { noTrunc ? $0.id : $0.shortId }.joined(separator: "\n")
        }
        let header = "REPOSITORY   TAG       IMAGE ID      CREATED   SIZE"
        let rows = images.map { img in
            let repo    = pad(img.repository, 12)
            let tag     = pad(img.tag, 10)
            let imgId   = noTrunc ? img.id : img.shortId
            let created = pad(relativeTime(img.createdAt), 10)
            let size    = formatSize(img.size)
            return "\(repo)   \(tag)   \(imgId)   \(created)   \(size)"
        }
        return ([header] + rows).joined(separator: "\n")
    }

    // MARK: - Networks

    public static func formatNetworks(_ networks: [NetworkInfo]) -> String {
        let header = "NETWORK ID     NAME      DRIVER    SCOPE"
        let rows = networks.map { net in
            let nid    = net.shortId
            let name   = pad(net.name, 10)
            let driver = pad(net.driver, 10)
            let scope  = net.scope
            return "\(nid)   \(name)   \(driver)   \(scope)"
        }
        return ([header] + rows).joined(separator: "\n")
    }

    // MARK: - Volumes

    public static func formatVolumes(_ volumes: [VolumeInfo]) -> String {
        let header = "DRIVER    VOLUME NAME"
        let rows = volumes.map { vol in
            "\(pad(vol.driver, 10))   \(vol.name)"
        }
        return ([header] + rows).joined(separator: "\n")
    }

    // MARK: - Relative time

    public static func relativeTime(_ date: Date) -> String {
        let elapsed = Int(Date().timeIntervalSince(date))
        switch elapsed {
        case ..<60:
            return "\(elapsed) seconds ago"
        case 60..<3600:
            return "\(elapsed / 60) minutes ago"
        case 3600..<86400:
            return "\(elapsed / 3600) hours ago"
        default:
            return "\(elapsed / 86400) days ago"
        }
    }

    // MARK: - Private helpers

    /// Pads `s` with spaces to reach `width`. If `s` is already wider, it is returned as-is (no truncation).
    private static func pad(_ s: String, _ width: Int) -> String {
        s.count >= width ? s : s + String(repeating: " ", count: width - s.count)
    }

    private static func formatSize(_ bytes: Int64) -> String {
        let kb: Int64 = 1024
        let mb = kb * 1024
        let gb = mb * 1024
        switch bytes {
        case ..<kb:
            return "\(bytes)B"
        case kb..<mb:
            return "\(bytes / kb)kB"
        case mb..<gb:
            return "\(bytes / mb)MB"
        default:
            return "\(bytes / gb)GB"
        }
    }
}
