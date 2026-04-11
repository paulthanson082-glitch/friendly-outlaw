import Foundation
import os.log
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - GuiNewService

/// Client for the gui.new REST API — converts HTML into shareable, live URLs.
///
/// **API overview**
/// - `POST /api/canvas`          — create a new canvas (HTML → URL)
/// - `PUT  /api/canvas/{id}`     — update existing canvas HTML
/// - `GET  /api/canvas/{id}`     — fetch canvas metadata
/// - `POST /api/canvas/{id}/extend` — extend expiry by 24 h
/// - `DELETE /api/canvas/{id}`   — delete a canvas
///
/// **Auth**: optional `Authorization: Bearer <GUI_NEW_API_KEY>` for Pro features.
///
/// Usage:
/// ```swift
/// let svc = GuiNewService()
/// let canvas = try await svc.createCanvas(html: "<h1>Hello</h1>", title: "My Page")
/// print(canvas.url)   // https://gui.new/<id>
/// ```
public class GuiNewService {

    // MARK: - Configuration

    private let baseURL: String
    private let apiKey: String?

    public init(apiKey: String? = nil, baseURL: String? = nil) {
        let env = ProcessInfo.processInfo.environment
        self.apiKey = apiKey ?? env["GUI_NEW_API_KEY"]

        // Validate baseURL for SSRF safety
        let configuredURL = baseURL ?? env["GUI_NEW_URL"] ?? "https://gui.new"
        if let urlObject = URL(string: configuredURL) {
            let ssrfResult = NetworkSecurity.validateSSRFSafety(url: urlObject)
            if !ssrfResult.isAllowed {
                // Log warning but use default HTTPS endpoint for safety
                os_log(
                    "GuiNewService: baseURL validation failed (%@), using default endpoint",
                    log: OSLog(subsystem: "com.writersapp.gui", category: "config"),
                    type: .warning,
                    ssrfResult.reason
                )
                self.baseURL = "https://gui.new"
            } else {
                self.baseURL = configuredURL
            }
        } else {
            self.baseURL = "https://gui.new"
        }
    }

    // MARK: - Private helpers

    private func headers() -> [String: String] {
        var h = ["Content-Type": "application/json"]
        if let key = apiKey, !key.isEmpty {
            h["Authorization"] = "Bearer \(key)"
        }
        return h
    }

    private func request(
        method: String,
        path: String,
        body: [String: Any]? = nil
    ) async throws -> Data {
        guard let url = URL(string: baseURL + path) else {
            throw GuiNewError.invalidURL
        }

        var req = URLRequest(url: url, timeoutInterval: 30)
        req.httpMethod = method
        for (k, v) in headers() { req.setValue(v, forHTTPHeaderField: k) }

        if let body {
            guard let data = try? JSONSerialization.data(withJSONObject: body) else {
                throw GuiNewError.encodingFailed
            }
            req.httpBody = data
        }

        let (data, response) = try await URLSession.shared.data(for: req)

        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            let bodyStr = String(data: data, encoding: .utf8) ?? ""
            throw GuiNewError.httpError(statusCode: http.statusCode, body: bodyStr)
        }

        return data
    }

    // MARK: - Public API

    /// Create a new canvas and return its metadata including shareable URL.
    @discardableResult
    public func createCanvas(html: String, title: String = "Untitled") async throws -> GuiCanvas {
        let data = try await request(
            method: "POST",
            path: "/api/canvas",
            body: ["html": html, "title": title]
        )
        guard let canvas = try? JSONDecoder().decode(GuiCanvas.self, from: data) else {
            throw GuiNewError.decodingFailed
        }
        return canvas
    }

    /// Update the HTML of an existing canvas (requires the edit token returned at creation).
    public func updateCanvas(id: String, html: String, editToken: String, title: String? = nil) async throws {
        var body: [String: Any] = ["html": html, "editToken": editToken]
        if let title { body["title"] = title }
        _ = try await request(method: "PUT", path: "/api/canvas/\(id)", body: body)
    }

    /// Fetch metadata for an existing canvas (no HTML body returned).
    public func getCanvas(id: String) async throws -> [String: Any] {
        let data = try await request(method: "GET", path: "/api/canvas/\(id)")
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw GuiNewError.decodingFailed
        }
        return obj
    }

    /// Extend a canvas's expiry by 24 hours.
    public func extendCanvas(id: String, editToken: String) async throws {
        _ = try await request(
            method: "POST",
            path: "/api/canvas/\(id)/extend",
            body: ["editToken": editToken]
        )
    }

    /// Delete a canvas permanently.
    public func deleteCanvas(id: String, editToken: String) async throws {
        _ = try await request(
            method: "DELETE",
            path: "/api/canvas/\(id)",
            body: ["editToken": editToken]
        )
    }

    // MARK: - HTML Builders

    /// Render a `Document` as a styled, shareable HTML page.
    public func createDocumentCanvas(document: Document, title: String? = nil) async throws -> GuiCanvas {
        let html = Self.documentHTML(document)
        return try await createCanvas(html: html, title: title ?? document.title)
    }

    /// Render app-level writing statistics as a visual dashboard canvas.
    public func createStatisticsCanvas(statistics: AppStatistics, title: String = "Writing Statistics") async throws -> GuiCanvas {
        let html = Self.statisticsHTML(statistics, title: title)
        return try await createCanvas(html: html, title: title)
    }

    /// Render a Kanban board as a visual columns-and-cards canvas.
    public func createKanbanCanvas(board: KanbanBoard, tasks: [KanbanTask], title: String? = nil) async throws -> GuiCanvas {
        let html = Self.kanbanHTML(board: board, tasks: tasks)
        return try await createCanvas(html: html, title: title ?? board.name)
    }

    // MARK: - HTML Templates

    static func documentHTML(_ doc: Document) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let created = dateFormatter.string(from: doc.metadata.created)
        let modified = dateFormatter.string(from: doc.metadata.modified)
        let escapedContent = escapeHTML(doc.content)
        let escapedTitle = escapeHTML(doc.title)

        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>\(escapedTitle)</title>
          <style>
            *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
            body {
              font-family: Georgia, 'Times New Roman', serif;
              background: #fafaf8;
              color: #1a1a1a;
              min-height: 100vh;
              padding: 40px 20px;
            }
            .wrapper { max-width: 740px; margin: 0 auto; }
            header {
              border-bottom: 2px solid #e0ddd8;
              padding-bottom: 24px;
              margin-bottom: 32px;
            }
            h1 {
              font-size: 2rem;
              font-weight: 700;
              line-height: 1.2;
              margin-bottom: 12px;
              color: #111;
            }
            .meta {
              display: flex;
              flex-wrap: wrap;
              gap: 16px;
              font-family: -apple-system, sans-serif;
              font-size: 0.78rem;
              color: #888;
            }
            .meta span { display: flex; align-items: center; gap: 4px; }
            .badge {
              background: #f0ede8;
              color: #555;
              padding: 2px 8px;
              border-radius: 99px;
              font-size: 0.72rem;
              font-weight: 500;
              text-transform: uppercase;
              letter-spacing: 0.04em;
            }
            .content {
              font-size: 1.05rem;
              line-height: 1.75;
              white-space: pre-wrap;
              color: #2c2c2c;
            }
            footer {
              margin-top: 48px;
              padding-top: 20px;
              border-top: 1px solid #e8e5e0;
              font-family: -apple-system, sans-serif;
              font-size: 0.75rem;
              color: #bbb;
              text-align: center;
            }
          </style>
        </head>
        <body>
          <div class="wrapper">
            <header>
              <h1>\(escapedTitle)</h1>
              <div class="meta">
                <span class="badge">\(doc.category.rawValue)</span>
                <span>&#128221; \(doc.wordCount) words</span>
                <span>&#128337; \(doc.readingTime) min read</span>
                <span>Created \(created)</span>
                <span>Updated \(modified)</span>
              </div>
            </header>
            <main class="content">\(escapedContent)</main>
            <footer>Exported from friendly-outlaw &middot; gui.new</footer>
          </div>
        </body>
        </html>
        """
    }

    static func statisticsHTML(_ stats: AppStatistics, title: String) -> String {
        let escapedTitle = escapeHTML(title)

        var categoryRows = ""
        for (cat, count) in stats.documentsByCategory.sorted(by: { $0.value > $1.value }) {
            categoryRows += """
            <tr>
              <td>\(escapeHTML(cat.rawValue))</td>
              <td class="num">\(count)</td>
            </tr>
            """
        }

        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>\(escapedTitle)</title>
          <style>
            *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
            body {
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
              background: #f4f4f6;
              color: #1a1a1a;
              min-height: 100vh;
              padding: 40px 20px;
            }
            h1 { font-size: 1.6rem; font-weight: 700; margin-bottom: 28px; color: #111; }
            .cards {
              display: grid;
              grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
              gap: 16px;
              margin-bottom: 36px;
            }
            .card {
              background: #fff;
              border-radius: 12px;
              padding: 20px 24px;
              box-shadow: 0 1px 4px rgba(0,0,0,.08);
            }
            .card .value {
              font-size: 2.2rem;
              font-weight: 800;
              color: #2563eb;
              line-height: 1;
            }
            .card .label {
              font-size: 0.78rem;
              color: #888;
              margin-top: 4px;
              text-transform: uppercase;
              letter-spacing: .04em;
            }
            h2 { font-size: 1rem; font-weight: 600; margin-bottom: 12px; color: #333; }
            table {
              width: 100%;
              border-collapse: collapse;
              background: #fff;
              border-radius: 12px;
              overflow: hidden;
              box-shadow: 0 1px 4px rgba(0,0,0,.08);
            }
            th, td { padding: 10px 16px; text-align: left; font-size: 0.88rem; }
            th { background: #f9f9fb; color: #555; font-weight: 600; border-bottom: 1px solid #efefef; }
            td { border-bottom: 1px solid #f4f4f6; }
            tr:last-child td { border-bottom: none; }
            .num { text-align: right; font-variant-numeric: tabular-nums; }
            footer {
              margin-top: 48px;
              font-size: 0.75rem;
              color: #bbb;
              text-align: center;
            }
          </style>
        </head>
        <body>
          <h1>\(escapedTitle)</h1>
          <div class="cards">
            <div class="card">
              <div class="value">\(stats.totalDocuments)</div>
              <div class="label">Documents</div>
            </div>
            <div class="card">
              <div class="value">\(GuiNewService.formatNumber(stats.totalWordCount))</div>
              <div class="label">Total Words</div>
            </div>
            <div class="card">
              <div class="value">\(stats.averageWordCount)</div>
              <div class="label">Avg Words / Doc</div>
            </div>
            <div class="card">
              <div class="value">\(stats.totalTemplates)</div>
              <div class="label">Templates</div>
            </div>
          </div>
          <h2>Documents by Category</h2>
          <table>
            <thead><tr><th>Category</th><th class="num">Count</th></tr></thead>
            <tbody>
              \(categoryRows.isEmpty ? "<tr><td colspan=\"2\" style=\"color:#bbb;text-align:center\">No documents yet</td></tr>" : categoryRows)
            </tbody>
          </table>
          <footer>Exported from friendly-outlaw &middot; gui.new</footer>
        </body>
        </html>
        """
    }

    static func kanbanHTML(board: KanbanBoard, tasks: [KanbanTask]) -> String {
        let columns: [KanbanColumn] = [.backlog, .planning, .running, .review, .done]
        let columnColors: [KanbanColumn: String] = [
            .backlog:  "#94a3b8",
            .planning: "#60a5fa",
            .running:  "#f59e0b",
            .review:   "#a78bfa",
            .done:     "#34d399"
        ]

        var columnsHTML = ""
        for col in columns {
            let colTasks = tasks.filter { $0.column == col }
            var cardsHTML = ""
            for task in colTasks {
                cardsHTML += """
                <div class="card">
                  <div class="card-title">\(escapeHTML(task.title))</div>
                  \(task.description.isEmpty ? "" : "<div class=\"card-desc\">\(escapeHTML(task.description))</div>")
                </div>
                """
            }
            let color = columnColors[col] ?? "#ccc"
            let count = colTasks.count
            columnsHTML += """
            <div class="column">
              <div class="col-header" style="border-top: 3px solid \(color)">
                <span class="col-title">\(escapeHTML(col.displayName))</span>
                <span class="col-count">\(count)</span>
              </div>
              <div class="cards">\(cardsHTML.isEmpty ? "<div class=\"empty\">No tasks</div>" : cardsHTML)</div>
            </div>
            """
        }

        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>\(escapeHTML(board.name))</title>
          <style>
            *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
            body {
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
              background: #f0f2f5;
              color: #1a1a1a;
              min-height: 100vh;
              padding: 32px 20px;
            }
            header { margin-bottom: 24px; }
            h1 { font-size: 1.5rem; font-weight: 700; }
            .desc { font-size: 0.88rem; color: #888; margin-top: 4px; }
            .board {
              display: flex;
              gap: 14px;
              overflow-x: auto;
              padding-bottom: 16px;
            }
            .column {
              background: #fff;
              border-radius: 12px;
              min-width: 220px;
              flex: 1;
              max-width: 280px;
              box-shadow: 0 1px 4px rgba(0,0,0,.07);
              display: flex;
              flex-direction: column;
            }
            .col-header {
              padding: 14px 16px 10px;
              display: flex;
              align-items: center;
              justify-content: space-between;
            }
            .col-title { font-weight: 600; font-size: 0.85rem; text-transform: uppercase; letter-spacing: .05em; color: #444; }
            .col-count {
              background: #f0f2f5;
              color: #888;
              font-size: 0.75rem;
              font-weight: 600;
              padding: 1px 7px;
              border-radius: 99px;
            }
            .cards { padding: 0 10px 12px; display: flex; flex-direction: column; gap: 8px; flex: 1; }
            .card {
              background: #f9fafb;
              border: 1px solid #e8eaed;
              border-radius: 8px;
              padding: 10px 12px;
            }
            .card-title { font-size: 0.88rem; font-weight: 500; line-height: 1.3; }
            .card-desc { font-size: 0.78rem; color: #888; margin-top: 4px; line-height: 1.4; }
            .empty { color: #ccc; font-size: 0.8rem; text-align: center; padding: 20px 0; }
            footer { margin-top: 32px; font-size: 0.75rem; color: #bbb; text-align: center; }
          </style>
        </head>
        <body>
          <header>
            <h1>\(escapeHTML(board.name))</h1>
            \(board.description.isEmpty ? "" : "<p class=\"desc\">\(escapeHTML(board.description))</p>")
          </header>
          <div class="board">\(columnsHTML)</div>
          <footer>Exported from friendly-outlaw &middot; gui.new</footer>
        </body>
        </html>
        """
    }

    // MARK: - Utility

    static func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    static func formatNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
