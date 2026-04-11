import Foundation

/// IP address validation utilities for SSRF protection
public enum IPAddressValidator {

    /// Checks if an IP address is in a reserved range (RFC 1918, RFC 3927, RFC 6598, etc.)
    /// Reserved ranges include loopback, link-local, multicast, broadcast, etc.
    public static func isReservedIP(_ ip: String) -> Bool {
        // IPv4 reserved ranges
        if isIPv4ReservedRange(ip) {
            return true
        }

        // IPv6 reserved ranges
        if isIPv6ReservedRange(ip) {
            return true
        }

        return false
    }

    /// Checks if an IP address is in a private range (RFC 1918)
    /// Private ranges: 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16
    public static func isPrivateIPRange(_ ip: String) -> Bool {
        // IPv4 private ranges
        if isIPv4PrivateRange(ip) {
            return true
        }

        // IPv6 private ranges (ULA - Unique Local Addresses)
        if isIPv6PrivateRange(ip) {
            return true
        }

        return false
    }

    /// Returns a human-readable description of the IP range
    public static func describeIPRange(_ ip: String) -> String {
        // IPv4
        if let parts = parseIPv4(ip) {
            let first = parts[0]

            if first == 0 { return "this network (0.0.0.0/8)" }
            if first == 10 { return "private (10.0.0.0/8)" }
            if first == 127 { return "loopback (127.0.0.0/8)" }
            if first == 169 { return "link-local (169.254.0.0/16)" }
            if first == 172 && parts[1] >= 16 && parts[1] <= 31 {
                return "private (172.16.0.0/12)"
            }
            if first == 192 && parts[1] == 168 { return "private (192.168.0.0/16)" }
            if first >= 224 && first <= 239 { return "multicast (224.0.0.0/4)" }
            if first == 255 { return "broadcast (255.255.255.255)" }
            if first >= 240 { return "reserved (240.0.0.0/4)" }
        }

        // IPv6
        if ip.contains(":") {
            if ip.hasPrefix("::1") { return "IPv6 loopback (::1)" }
            if ip.hasPrefix("fc") || ip.hasPrefix("fd") {
                return "IPv6 ULA (fc00::/7)"
            }
            if ip.hasPrefix("fe80") { return "IPv6 link-local (fe80::/10)" }
            if ip.hasPrefix("ff") { return "IPv6 multicast (ff00::/8)" }
        }

        return "unknown IP range"
    }

    // MARK: - IPv4 Helpers

    private static func isIPv4ReservedRange(_ ip: String) -> Bool {
        guard let parts = parseIPv4(ip) else { return false }

        let first = parts[0]
        let second = parts[1]

        // 0.0.0.0/8 - This network
        if first == 0 { return true }

        // 127.0.0.0/8 - Loopback
        if first == 127 { return true }

        // 169.254.0.0/16 - Link-local
        if first == 169 && second == 254 { return true }

        // 224.0.0.0/4 - Multicast
        if first >= 224 && first <= 239 { return true }

        // 240.0.0.0/4 - Reserved for future use
        if first >= 240 && first <= 255 { return true }

        return false
    }

    private static func isIPv4PrivateRange(_ ip: String) -> Bool {
        guard let parts = parseIPv4(ip) else { return false }

        let first = parts[0]
        let second = parts[1]

        // 10.0.0.0/8
        if first == 10 { return true }

        // 172.16.0.0/12
        if first == 172 && second >= 16 && second <= 31 { return true }

        // 192.168.0.0/16
        if first == 192 && second == 168 { return true }

        return false
    }

    private static func parseIPv4(_ ip: String) -> [Int]? {
        let parts = ip.split(separator: ".").compactMap { Int($0) }
        guard parts.count == 4 else { return nil }
        return parts
    }

    // MARK: - IPv6 Helpers

    private static func isIPv6ReservedRange(_ ip: String) -> Bool {
        guard ip.contains(":") else { return false }

        let lowercased = ip.lowercased()

        // ::1 - Loopback
        if lowercased == "::1" || lowercased.starts(with: "::1/") { return true }

        // ::ffff:0:0/96 - IPv4-mapped IPv6
        if lowercased.starts(with: "::ffff:") { return true }

        // ff00::/8 - Multicast
        if lowercased.starts(with: "ff") { return true }

        return false
    }

    private static func isIPv6PrivateRange(_ ip: String) -> Bool {
        guard ip.contains(":") else { return false }

        let lowercased = ip.lowercased()

        // fc00::/7 - Unique Local Addresses (ULA)
        if lowercased.starts(with: "fc") || lowercased.starts(with: "fd") { return true }

        // fe80::/10 - Link-local
        if lowercased.starts(with: "fe80") { return true }

        return false
    }
}
