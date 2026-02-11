import Foundation
import CSQLite

// SQLite constant for transient text binding
private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/// Get the database path from environment variable or use default
func getDatabasePath() -> String {
    if let envPath = ProcessInfo.processInfo.environment["WRITERS_APP_DATA_DIR"] {
        return (envPath as NSString).appendingPathComponent("writersapp.db")
    }
    
    // Default path in user's documents directory
    let fileManager = FileManager.default
    let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.path ?? ""
    return (documentsPath as NSString).appendingPathComponent("writersapp.db")
}

/// Extract project name from path
func getProjectName(from path: String) -> String {
    return (path as NSString).lastPathComponent
}

/// Get counts for a specific project
func getProjectCounts(projectPath: String) -> (suggestions: Int, sessions: Int) {
    let dbPath = getDatabasePath()
    let projectName = getProjectName(from: projectPath)
    
    var db: OpaquePointer?
    
    // Try to open database
    guard sqlite3_open(dbPath, &db) == SQLITE_OK, let database = db else {
        // Return zeros on any error (graceful fallback)
        return (0, 0)
    }
    
    defer {
        sqlite3_close(database)
    }
    
    var suggestionsCount = 0
    var sessionsCount = 0
    
    // Count AI suggestions for this project
    let suggestionsSQL = """
    SELECT COUNT(*) FROM AI_Suggestions WHERE project = ?;
    """
    
    var statement: OpaquePointer?
    if sqlite3_prepare_v2(database, suggestionsSQL, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_text(statement, 1, projectName, -1, SQLITE_TRANSIENT)
        
        if sqlite3_step(statement) == SQLITE_ROW {
            suggestionsCount = Int(sqlite3_column_int(statement, 0))
        }
        sqlite3_finalize(statement)
    }
    
    // Count user sessions for this project
    let sessionsSQL = """
    SELECT COUNT(*) FROM User_Sessions WHERE project = ?;
    """
    
    statement = nil
    if sqlite3_prepare_v2(database, sessionsSQL, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_text(statement, 1, projectName, -1, SQLITE_TRANSIENT)
        
        if sqlite3_step(statement) == SQLITE_ROW {
            sessionsCount = Int(sqlite3_column_int(statement, 0))
        }
        sqlite3_finalize(statement)
    }
    
    return (suggestionsCount, sessionsCount)
}

/// Main entry point
func main() {
    let args = CommandLine.arguments
    
    guard args.count > 1 else {
        // Return zeros if no project path provided
        let result = ["suggestions": 0, "sessions": 0, "project": ""] as [String : Any]
        if let jsonData = try? JSONSerialization.data(withJSONObject: result),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
        return
    }
    
    let projectPath = args[1]
    let projectName = getProjectName(from: projectPath)
    let counts = getProjectCounts(projectPath: projectPath)
    
    // Output JSON
    let result: [String: Any] = [
        "suggestions": counts.suggestions,
        "sessions": counts.sessions,
        "project": projectName
    ]
    
    if let jsonData = try? JSONSerialization.data(withJSONObject: result, options: [.sortedKeys]),
       let jsonString = String(data: jsonData, encoding: .utf8) {
        print(jsonString)
    } else {
        // Fallback to zeros on JSON serialization error
        print("{\"sessions\":0,\"suggestions\":0,\"project\":\"\(projectName)\"}")
    }
}

main()
