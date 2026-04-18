import ArgumentParser
import Foundation

// MARK: - Ubuntu Manpage Operator

@main
struct ManpageOperator: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "manop",
        abstract: "Ubuntu Manpage Operator — browse, search, and inspect Ubuntu man pages.",
        discussion: """
        manop interfaces with the local man-db and Ubuntu manpages to let you
        quickly show, search, and list manual pages from the command line.

        Examples:
          manop show ls              Show the man page for 'ls'
          manop show ls --section 1  Show section 1 of 'ls'
          manop search copy          Search for man pages mentioning 'copy'
          manop whatis tar           One-line description of 'tar'
          manop list --section 1     List all man pages in section 1
          manop sections             List available manual sections
        """,
        version: "1.0.0",
        subcommands: [
            ShowCommand.self,
            SearchCommand.self,
            WhатisCommand.self,
            ListCommand.self,
            SectionsCommand.self,
        ],
        defaultSubcommand: ShowCommand.self
    )
}

// MARK: - Shared utilities

enum ManpageError: Error, CustomStringConvertible {
    case commandNotFound(String)
    case processError(String)
    case noResults(String)

    var description: String {
        switch self {
        case .commandNotFound(let cmd):
            return "Command not found: '\(cmd)'. Is man-db installed? Try: sudo apt install man-db"
        case .processError(let msg):
            return "Process error: \(msg)"
        case .noResults(let query):
            return "No man pages found for: '\(query)'"
        }
    }
}

/// Run an external command and return its combined stdout+stderr output and exit code.
func runProcess(command: String, arguments: [String], environment: [String: String]? = nil) -> (output: String, exitCode: Int32) {
    let process = Process()
    let outputPipe = Pipe()
    let errorPipe = Pipe()

    process.executableURL = URL(fileURLWithPath: command)
    process.arguments = arguments
    process.standardOutput = outputPipe
    process.standardError = errorPipe

    if let env = environment {
        var baseEnv = ProcessInfo.processInfo.environment
        for (k, v) in env { baseEnv[k] = v }
        process.environment = baseEnv
    }

    do {
        try process.launch()
        process.waitUntilExit()
    } catch {
        return ("Failed to launch \(command): \(error)", -1)
    }

    let outData = outputPipe.fileHandleForReading.readDataToEndOfFile()
    let errData = errorPipe.fileHandleForReading.readDataToEndOfFile()
    let output = (String(data: outData, encoding: .utf8) ?? "") +
                 (String(data: errData, encoding: .utf8) ?? "")
    return (output, process.terminationStatus)
}

/// Locate a binary in common PATH locations.
func resolveExecutable(_ name: String) -> String? {
    let searchPaths = ["/usr/bin", "/bin", "/usr/sbin", "/sbin", "/usr/local/bin"]
    for dir in searchPaths {
        let path = "\(dir)/\(name)"
        if FileManager.default.fileExists(atPath: path) {
            return path
        }
    }
    return nil
}

// MARK: - show

struct ShowCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "show",
        abstract: "Display the man page for a command."
    )

    @Argument(help: "The command or topic to look up.")
    var command: String

    @Option(name: [.short, .customLong("section")], help: "Manual section number (1–9).")
    var section: String?

    @Flag(name: .customLong("plain"), help: "Output plain text without formatting codes.")
    var plain: Bool = false

    func run() async throws {
        guard let manPath = resolveExecutable("man") else {
            throw ManpageError.commandNotFound("man")
        }

        // Build argument list
        var args: [String] = []
        if plain {
            // col -b strips backspace-based formatting from nroff output
            args += ["--no-hyphenation", "--no-justification"]
        }
        if let sec = section {
            args.append(sec)
        }
        args.append(command)

        let env: [String: String] = plain ? ["MANPAGER": "cat", "PAGER": "cat"] : ["PAGER": "cat"]
        let (output, exitCode) = runProcess(command: manPath, arguments: args, environment: env)

        guard exitCode == 0 else {
            if output.lowercased().contains("no manual entry") || output.isEmpty {
                throw ManpageError.noResults(command)
            }
            throw ManpageError.processError(output.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        if plain {
            // Strip backspace-based bold/underline escape sequences (col -b behaviour)
            let stripped = stripManFormatting(output)
            print(stripped)
        } else {
            print(output)
        }
    }
}

// MARK: - search (apropos)

struct SearchCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "search",
        abstract: "Search man page names and descriptions (apropos)."
    )

    @Argument(help: "Keyword or regex to search for.")
    var query: String

    @Option(name: [.short, .customLong("section")], help: "Limit results to a specific section.")
    var section: String?

    @Flag(name: [.short, .customLong("exact")], help: "Match exact command names only.")
    var exact: Bool = false

    func run() async throws {
        guard let aproposPath = resolveExecutable("apropos") else {
            throw ManpageError.commandNotFound("apropos")
        }

        var args: [String] = []
        if exact { args += ["--exact"] }
        if let sec = section { args += ["--section", sec] }
        args.append(query)

        let (output, exitCode) = runProcess(command: aproposPath, arguments: args)

        if exitCode != 0 || output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ManpageError.noResults(query)
        }

        let lines = output.split(separator: "\n", omittingEmptySubsequences: true)
        print("Found \(lines.count) result(s) for '\(query)':\n")
        for line in lines {
            print("  \(line)")
        }
    }
}

// MARK: - whatis

struct WhатisCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "whatis",
        abstract: "Display one-line descriptions for commands."
    )

    @Argument(help: "Commands to look up (space-separated).", completion: .default)
    var commands: [String]

    func run() async throws {
        guard let whatisPath = resolveExecutable("whatis") else {
            throw ManpageError.commandNotFound("whatis")
        }

        guard !commands.isEmpty else {
            print("Provide at least one command name.")
            return
        }

        let (output, exitCode) = runProcess(command: whatisPath, arguments: commands)

        if exitCode != 0 || output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ManpageError.noResults(commands.joined(separator: ", "))
        }

        print(output)
    }
}

// MARK: - list

struct ListCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List available man pages, optionally filtered by section."
    )

    @Option(name: [.short, .customLong("section")], help: "Section to list (1–9, default: all).")
    var section: String?

    @Option(name: [.short, .customLong("limit")], help: "Maximum number of results to show (default: 50).")
    var limit: Int = 50

    @Flag(name: [.customLong("count")], help: "Show only the total count.")
    var countOnly: Bool = false

    func run() async throws {
        // Enumerate /usr/share/man directories
        let manRoot = "/usr/share/man"
        let fm = FileManager.default

        guard fm.fileExists(atPath: manRoot) else {
            throw ManpageError.commandNotFound("manpages directory (\(manRoot))")
        }

        let sections: [String]
        if let sec = section {
            sections = ["man\(sec)"]
        } else {
            // Enumerate all manN subdirectories
            let contents = (try? fm.contentsOfDirectory(atPath: manRoot)) ?? []
            sections = contents
                .filter { $0.hasPrefix("man") && $0.count == 4 }
                .sorted()
        }

        var entries: [(section: String, name: String)] = []

        for sectionDir in sections {
            let sectionPath = "\(manRoot)/\(sectionDir)"
            guard let files = try? fm.contentsOfDirectory(atPath: sectionPath) else { continue }
            let sectionNum = String(sectionDir.dropFirst(3)) // "man1" -> "1"
            for file in files.sorted() {
                // Strip extensions: ls.1.gz -> ls
                let name = stripManExtensions(file)
                entries.append((section: sectionNum, name: name))
            }
        }

        if countOnly {
            print("Total man pages available: \(entries.count)")
            return
        }

        let displayed = entries.prefix(limit)
        let sectionLabel = section.map { "section \($0)" } ?? "all sections"
        print("Man pages (\(sectionLabel)) — showing \(displayed.count) of \(entries.count):\n")

        var lastSection = ""
        for entry in displayed {
            if entry.section != lastSection {
                print("  Section \(entry.section):")
                lastSection = entry.section
            }
            print("    \(entry.name)(\(entry.section))")
        }

        if entries.count > limit {
            print("\n  ... and \(entries.count - limit) more. Use --limit to show more.")
        }
    }
}

// MARK: - sections

struct SectionsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "sections",
        abstract: "List available manual sections with descriptions."
    )

    func run() async throws {
        let sectionDescriptions: [(String, String)] = [
            ("1", "Executable programs and shell commands"),
            ("2", "System calls (kernel functions)"),
            ("3", "Library calls (functions in program libraries)"),
            ("4", "Special files (usually in /dev)"),
            ("5", "File formats and conventions"),
            ("6", "Games and screensavers"),
            ("7", "Miscellaneous (macro packages, conventions)"),
            ("8", "System administration commands (root only)"),
            ("9", "Kernel routines (non-standard)"),
        ]

        let manRoot = "/usr/share/man"
        let fm = FileManager.default
        let available = (try? fm.contentsOfDirectory(atPath: manRoot)) ?? []

        print("Ubuntu Manual Sections:\n")
        for (num, desc) in sectionDescriptions {
            let dirName = "man\(num)"
            let exists = available.contains(dirName)
            let count: Int
            if exists, let files = try? fm.contentsOfDirectory(atPath: "\(manRoot)/\(dirName)") {
                count = files.count
            } else {
                count = 0
            }
            let status = exists ? "(\(count) pages)" : "(not installed)"
            print("  Section \(num): \(desc)")
            print("           \(status)\n")
        }
    }
}

// MARK: - Formatting helpers

/// Strip nroff backspace-based bold/underline formatting (char BS char sequences).
func stripManFormatting(_ text: String) -> String {
    var result = ""
    var chars = Array(text.unicodeScalars)
    var i = 0
    while i < chars.count {
        if i + 2 < chars.count, chars[i + 1].value == 8 { // ASCII backspace
            // Either bold (x BS x) or underline (_ BS x) — keep the visible char
            result.append(Character(chars[i + 2]))
            i += 3
        } else {
            result.append(Character(chars[i]))
            i += 1
        }
    }
    return result
}

/// Strip file extensions from a man page filename: ls.1.gz -> ls
func stripManExtensions(_ filename: String) -> String {
    var name = filename
    // Remove .gz or .bz2
    if name.hasSuffix(".gz") { name = String(name.dropLast(3)) }
    else if name.hasSuffix(".bz2") { name = String(name.dropLast(4)) }
    // Remove .N section suffix
    if let dotRange = name.lastIndex(of: ".") {
        name = String(name[name.startIndex..<dotRange])
    }
    return name
}
