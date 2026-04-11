import Foundation
import os.log

/// SSRF (Server-Side Request Forgery) validation mode
public enum SSRFValidationMode: String, Codable {
    case strict      // Default: block all private/reserved IPs
    case permissive  // Allow private IPs with logging
    case disabled    // No validation (development only)
}

/// Result of SSRF validation check
public struct SSRFCheckResult {
    public let isAllowed: Bool
    public let reason: String
    public let resolvedIP: String?

    public init(isAllowed: Bool, reason: String, resolvedIP: String? = nil) {
        self.isAllowed = isAllowed
        self.reason = reason
        self.resolvedIP = resolvedIP
    }
}

/// Network security utilities for preventing SSRF attacks
public enum NetworkSecurity {
    private static let logger = OSLog(
        subsystem: "com.writersapp.security",
        category: "network"
    )

    /// Validates a URL for SSRF safety
    /// - Parameters:
    ///   - url: The URL to validate
    ///   - mode: Validation mode (default: strict)
    ///   - whitelist: Optional list of allowed IP addresses to bypass checks
    /// - Returns: SSRFCheckResult indicating if the URL is safe to fetch
    /// - Throws: Never throws; returns failed result instead
    public static func validateSSRFSafety(
        url: URL,
        mode: SSRFValidationMode = .strict,
        whitelist: [String] = []
    ) -> SSRFCheckResult {
        // Disabled mode: allow everything
        if mode == .disabled {
            return SSRFCheckResult(isAllowed: true, reason: "SSRF validation disabled")
        }

        // Validate scheme
        guard let scheme = url.scheme, scheme.lowercased() == "http" || scheme.lowercased() == "https" else {
            let reason = "Invalid scheme: only http/https allowed"
            logSSRFAttempt(url: url, reason: reason)
            return SSRFCheckResult(isAllowed: false, reason: reason)
        }

        // Extract host
        guard let host = url.host else {
            let reason = "Unable to extract host from URL"
            logSSRFAttempt(url: url, reason: reason)
            return SSRFCheckResult(isAllowed: false, reason: reason)
        }

        // Check if host is in whitelist
        if whitelist.contains(host) {
            os_log("SSRF: Host %@ whitelisted", log: logger, type: .info, host)
            return SSRFCheckResult(isAllowed: true, reason: "Host whitelisted", resolvedIP: host)
        }

        // Try to resolve hostname to IP
        let resolvedIP = resolveHostname(host)

        // Check for private/reserved IP ranges
        if let ip = resolvedIP {
            if IPAddressValidator.isReservedIP(ip) {
                let reason = "IP in reserved range: \(IPAddressValidator.describeIPRange(ip))"
                logSSRFAttempt(url: url, reason: reason, ip: ip)

                if mode == .permissive {
                    os_log("SSRF: Allowing reserved IP in permissive mode: %@", log: logger, type: .warning, ip)
                    return SSRFCheckResult(isAllowed: true, reason: reason, resolvedIP: ip)
                }
                return SSRFCheckResult(isAllowed: false, reason: reason, resolvedIP: ip)
            }

            if IPAddressValidator.isPrivateIPRange(ip) {
                let reason = "IP in private range: \(IPAddressValidator.describeIPRange(ip))"
                logSSRFAttempt(url: url, reason: reason, ip: ip)

                if mode == .permissive {
                    os_log("SSRF: Allowing private IP in permissive mode: %@", log: logger, type: .warning, ip)
                    return SSRFCheckResult(isAllowed: true, reason: reason, resolvedIP: ip)
                }
                return SSRFCheckResult(isAllowed: false, reason: reason, resolvedIP: ip)
            }
        }

        return SSRFCheckResult(isAllowed: true, reason: "URL passed SSRF validation", resolvedIP: resolvedIP)
    }

    /// Resolves a hostname to an IP address using DNS
    /// - Parameter hostname: The hostname to resolve
    /// - Returns: The resolved IP address string, or nil if resolution fails
    private static func resolveHostname(_ hostname: String) -> String? {
        // Check if already an IP address
        if isIPAddress(hostname) {
            return hostname
        }

        var hints = addrinfo()
        hints.ai_family = AF_UNSPEC
        hints.ai_socktype = SOCK_STREAM
        hints.ai_flags = 0

        var result: UnsafeMutablePointer<addrinfo>?
        let status = getaddrinfo(hostname, nil, &hints, &result)

        guard status == 0, let res = result else {
            os_log("SSRF: DNS resolution failed for %@", log: logger, type: .debug, hostname)
            return nil
        }

        defer { freeaddrinfo(res) }

        var current = res
        while current != nil {
            let addr = current!.pointee
            var ip = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))

            if addr.ai_family == AF_INET {
                let sockaddr = withUnsafeBytes(of: addr.ai_addr.pointee) { $0 }
                let ipv4 = sockaddr.load(as: sockaddr_in.self)
                inet_ntop(AF_INET, &ipv4.sin_addr, &ip, socklen_t(INET_ADDRSTRLEN))
            } else if addr.ai_family == AF_INET6 {
                let sockaddr = withUnsafeBytes(of: addr.ai_addr.pointee) { $0 }
                let ipv6 = sockaddr.load(as: sockaddr_in6.self)
                inet_ntop(AF_INET6, &ipv6.sin6_addr, &ip, socklen_t(INET6_ADDRSTRLEN))
            }

            if !ip.isEmpty {
                let resolvedIP = String(cString: ip)
                os_log("SSRF: Resolved %@ to %@", log: logger, type: .debug, hostname, resolvedIP)
                return resolvedIP
            }

            current = addr.ai_next
        }

        return nil
    }

    /// Checks if a string is already an IP address
    private static func isIPAddress(_ string: String) -> Bool {
        var sin = sockaddr_in()
        var sin6 = sockaddr_in6()

        return inet_pton(AF_INET, string, &sin.sin_addr) == 1 ||
               inet_pton(AF_INET6, string, &sin6.sin6_addr) == 1
    }

    /// Logs SSRF attempt to system log
    private static func logSSRFAttempt(url: URL, reason: String, ip: String? = nil) {
        let urlString = url.absoluteString
        let message = ip.map { "URL: \($0)" } ?? urlString

        os_log(
            "SSRF attempt blocked: %@ - Reason: %@",
            log: logger,
            type: .error,
            message,
            reason
        )
    }
}
