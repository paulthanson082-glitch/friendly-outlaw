import Foundation
import CSQLite

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

func getDatabasePath() -> String {
    if let envPath = ProcessInfo.processInfo.environment["WRITERS_APP_DATA_DIR"] {
        return (envPath as NSString).appendingPathComponent("writersapp.db")
    }
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path ?? ""
    return (documentsPath as NSString).appendingPathComponent("writersapp.db")
}

func getProjectName(from path: String) -> String {
    return (path as NSString).lastPathComponent
}

func getProjectCounts(projectPath: String) -> (suggestions: Int, sessions: Int) {
    let dbPath = getDatabasePath()
    let projectName = getProjectName(from: projectPath)

    var db: OpaquePointer?
    guard sqlite3_open(dbPath, &db) == SQLITE_OK, let database = db else {
        return (0, 0)
    }
    defer { sqlite3_close(database) }

    var suggestionsCount = 0
    var sessionsCount = 0
    var stmt: OpaquePointer?

    if sqlite3_prepare_v2(database, "SELECT COUNT(*) FROM AI_Suggestions WHERE project = ?;", -1, &stmt, nil) == SQLITE_OK {
        sqlite3_bind_text(stmt, 1, projectName, -1, SQLITE_TRANSIENT)
        if sqlite3_step(stmt) == SQLITE_ROW { suggestionsCount = Int(sqlite3_column_int(stmt, 0)) }
        sqlite3_finalize(stmt)
    }

    stmt = nil
    if sqlite3_prepare_v2(database, "SELECT COUNT(*) FROM User_Sessions WHERE project = ?;", -1, &stmt, nil) == SQLITE_OK {
        sqlite3_bind_text(stmt, 1, projectName, -1, SQLITE_TRANSIENT)
        if sqlite3_step(stmt) == SQLITE_ROW { sessionsCount = Int(sqlite3_column_int(stmt, 0)) }
        sqlite3_finalize(stmt)
    }

    return (suggestionsCount, sessionsCount)
}

func main() {
    let args = CommandLine.arguments
    guard args.count > 1 else {
        print("{\"suggestions\":0,\"sessions\":0,\"project\":\"\"}")
        return
    }
    let projectPath = args[1]
    let projectName = getProjectName(from: projectPath)
    let counts = getProjectCounts(projectPath: projectPath)
    let result: [String: Any] = ["suggestions": counts.suggestions, "sessions": counts.sessions, "project": projectName]
    if let data = try? JSONSerialization.data(withJSONObject: result, options: [.sortedKeys]),
       let json = String(data: data, encoding: .utf8) {
        print(json)
    } else {
        print("{\"sessions\":\(counts.sessions),\"suggestions\":\(counts.suggestions),\"project\":\"\(projectName)\"}")
    }
}

main()
