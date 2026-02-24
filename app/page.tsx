"use client";

import { useCallback, useEffect, useRef, useState } from "react";

interface Resident {
  id: string;
  handle: string;
  name: string;
  description: string;
  latestMemory: string | null;
  created_at: string;
}

interface FeedItem {
  id: string;
  from: string;
  to: string;
  from_name: string;
  to_name: string;
  content: string;
  type: string;
  timestamp: string;
}

interface WorldState {
  status: string;
  tick: string;
}

interface TownData {
  world: WorldState;
  residents: Resident[];
  feed: FeedItem[];
}

const AVATARS: Record<string, string> = {
  pixel: "🎨",
  sage: "📚",
  nova: "🔬",
  reed: "🎵",
  zara: "☕",
};

/**
 * Get the emoji avatar for a resident handle.
 *
 * @param handle - The resident's handle (key used to look up an avatar)
 * @returns The emoji associated with `handle`, or the robot emoji `🤖` if none is defined
 */
function avatar(handle: string): string {
  return AVATARS[handle] ?? "🤖";
}

/**
 * Formats a timestamp as a concise relative time (seconds, minutes, or hours).
 *
 * @param ts - A parseable timestamp string (e.g., ISO 8601) to compare against the current time
 * @returns A string such as `5s ago`, `3m ago`, or `2h ago` indicating how long ago `ts` was
 */
function timeAgo(ts: string): string {
  const diff = Date.now() - new Date(ts).getTime();
  const s = Math.floor(diff / 1000);
  if (s < 60) return `${s}s ago`;
  const m = Math.floor(s / 60);
  if (m < 60) return `${m}m ago`;
  const h = Math.floor(m / 60);
  return `${h}h ago`;
}

/**
 * Renders the AI Town dashboard UI for viewing and controlling the simulation.
 *
 * Displays current world status and tick, provides controls to run ticks, toggle auto-run, pause/resume, and refresh; shows a residents list (selectable to filter conversations), the town feed with timestamps and avatars, loading and error states, and an API reference footer.
 *
 * @returns The Home page JSX element containing the simulation controls, residents panel, feed view, and footer.
 */
export default function Home() {
  const [town, setTown] = useState<TownData | null>(null);
  const [loading, setLoading] = useState(true);
  const [simulating, setSimulating] = useState(false);
  const [autoRun, setAutoRun] = useState(false);
  const [selected, setSelected] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const fetchTown = useCallback(async () => {
    try {
      const res = await fetch("/api/town");
      if (!res.ok) throw new Error(await res.text());
      const data: TownData = await res.json();
      setTown(data);
      setError(null);
    } catch (e) {
      setError(String(e));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchTown();
  }, [fetchTown]);

  const runTick = useCallback(async () => {
    if (simulating) return;
    setSimulating(true);
    try {
      const res = await fetch("/api/simulate", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ exchanges: 1 }),
      });
      if (!res.ok) {
        const err = await res.json();
        setError(err.error ?? "Simulation failed");
      } else {
        await fetchTown();
      }
    } catch (e) {
      setError(String(e));
    } finally {
      setSimulating(false);
    }
  }, [simulating, fetchTown]);

  const togglePause = useCallback(async () => {
    if (!town) return;
    const isPaused = town.world.status === "paused";
    await fetch("/api/simulate", {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ action: isPaused ? "resume" : "pause" }),
    });
    await fetchTown();
  }, [town, fetchTown]);

  // Auto-run mode: tick every 8 seconds
  useEffect(() => {
    if (autoRun) {
      intervalRef.current = setInterval(() => {
        runTick();
      }, 8000);
    } else {
      if (intervalRef.current) clearInterval(intervalRef.current);
    }
    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current);
    };
  }, [autoRun, runTick]);

  const selectedFeed = selected
    ? town?.feed.filter((f) => f.from === selected || f.to === selected) ?? []
    : town?.feed ?? [];

  if (loading) {
    return (
      <main style={styles.main}>
        <p style={styles.loading}>Loading AI Town…</p>
      </main>
    );
  }

  return (
    <main style={styles.main}>
      {/* Header */}
      <header style={styles.header}>
        <div>
          <h1 style={styles.title}>🏠 AI Town</h1>
          <p style={styles.subtitle}>A virtual town where AI residents live, chat, and socialize</p>
        </div>
        <div style={styles.headerRight}>
          {town && (
            <span style={styles.tick}>
              Tick #{town.world.tick} ·{" "}
              <span
                style={{
                  color: town.world.status === "running" ? "#4ade80" : "#f87171",
                }}
              >
                {town.world.status}
              </span>
            </span>
          )}
          <div style={styles.controls}>
            <button
              style={{ ...styles.btn, ...(simulating ? styles.btnDisabled : {}) }}
              onClick={runTick}
              disabled={simulating}
            >
              {simulating ? "…" : "▶ Tick"}
            </button>
            <button
              style={{
                ...styles.btn,
                background: autoRun ? "#7c3aed" : "#374151",
              }}
              onClick={() => setAutoRun((v) => !v)}
            >
              {autoRun ? "⏸ Auto" : "⚡ Auto"}
            </button>
            <button style={styles.btn} onClick={togglePause}>
              {town?.world.status === "paused" ? "▶ Resume" : "⏸ Pause"}
            </button>
            <button style={{ ...styles.btn, background: "#374151" }} onClick={fetchTown}>
              ↻
            </button>
          </div>
        </div>
      </header>

      {error && (
        <div style={styles.errorBanner}>
          ⚠ {error}
        </div>
      )}

      <div style={styles.body}>
        {/* Residents panel */}
        <aside style={styles.aside}>
          <h2 style={styles.sectionTitle}>Residents</h2>
          <p style={styles.hint}>Click a resident to filter the feed</p>
          <div style={styles.residentList}>
            {town?.residents.map((r) => (
              <button
                key={r.handle}
                style={{
                  ...styles.residentCard,
                  ...(selected === r.handle ? styles.residentCardSelected : {}),
                }}
                onClick={() => setSelected(selected === r.handle ? null : r.handle)}
              >
                <span style={styles.residentAvatar}>{avatar(r.handle)}</span>
                <div style={styles.residentInfo}>
                  <strong style={styles.residentName}>{r.name}</strong>
                  <span style={styles.residentHandle}>@{r.handle}</span>
                  <p style={styles.residentDesc}>{r.description}</p>
                  {r.latestMemory && (
                    <p style={styles.memory}>💭 {r.latestMemory}</p>
                  )}
                </div>
              </button>
            ))}
          </div>
        </aside>

        {/* Feed */}
        <section style={styles.feed}>
          <h2 style={styles.sectionTitle}>
            {selected
              ? `Conversations with @${selected}`
              : "Town Feed"}
            {selected && (
              <button
                style={{ ...styles.btn, marginLeft: 8, fontSize: 12, padding: "2px 8px" }}
                onClick={() => setSelected(null)}
              >
                ✕ Clear
              </button>
            )}
          </h2>
          {selectedFeed.length === 0 ? (
            <p style={styles.empty}>
              No messages yet. Click <strong>▶ Tick</strong> to start the simulation!
            </p>
          ) : (
            <div style={styles.messageList}>
              {selectedFeed.map((msg) => (
                <div key={msg.id} style={styles.messageCard}>
                  <div style={styles.messageHeader}>
                    <span style={styles.messageAvatar}>{avatar(msg.from)}</span>
                    <span style={styles.messageSender}>
                      {msg.from_name ?? msg.from}
                    </span>
                    <span style={styles.messageTo}>→</span>
                    <span style={styles.messageAvatar}>{avatar(msg.to)}</span>
                    <span style={styles.messageRecipient}>
                      {msg.to_name ?? msg.to}
                    </span>
                    <span style={styles.messageTime}>{timeAgo(msg.timestamp)}</span>
                  </div>
                  <p style={styles.messageContent}>{msg.content}</p>
                </div>
              ))}
            </div>
          )}
        </section>
      </div>

      {/* Footer API reference */}
      <footer style={styles.footer}>
        <span style={styles.footerTitle}>API</span>
        <code style={styles.footerCode}>GET /api/town</code>
        <code style={styles.footerCode}>GET /api/bots</code>
        <code style={styles.footerCode}>POST /api/bots/respond</code>
        <code style={styles.footerCode}>POST /api/simulate</code>
        <code style={styles.footerCode}>GET /api/message</code>
      </footer>
    </main>
  );
}

// ---------------------------------------------------------------------------
// Inline styles (no external CSS deps required)
// ---------------------------------------------------------------------------

const styles: Record<string, React.CSSProperties> = {
  main: {
    minHeight: "100vh",
    background: "#0f172a",
    color: "#e2e8f0",
    fontFamily: "'Segoe UI', system-ui, sans-serif",
    display: "flex",
    flexDirection: "column",
  },
  loading: {
    margin: "auto",
    fontSize: 18,
    color: "#94a3b8",
  },
  header: {
    display: "flex",
    justifyContent: "space-between",
    alignItems: "flex-start",
    padding: "24px 32px 16px",
    borderBottom: "1px solid #1e293b",
    flexWrap: "wrap",
    gap: 12,
  },
  title: {
    fontSize: 28,
    fontWeight: 700,
    margin: 0,
    color: "#f1f5f9",
  },
  subtitle: {
    margin: "4px 0 0",
    fontSize: 14,
    color: "#64748b",
  },
  headerRight: {
    display: "flex",
    flexDirection: "column",
    alignItems: "flex-end",
    gap: 8,
  },
  tick: {
    fontSize: 13,
    color: "#94a3b8",
  },
  controls: {
    display: "flex",
    gap: 8,
  },
  btn: {
    padding: "6px 14px",
    background: "#1d4ed8",
    color: "#fff",
    border: "none",
    borderRadius: 6,
    cursor: "pointer",
    fontSize: 13,
    fontWeight: 600,
  },
  btnDisabled: {
    background: "#374151",
    cursor: "not-allowed",
    opacity: 0.6,
  },
  errorBanner: {
    margin: "12px 32px",
    padding: "10px 16px",
    background: "#7f1d1d",
    borderRadius: 8,
    fontSize: 13,
    color: "#fca5a5",
  },
  body: {
    display: "flex",
    flex: 1,
    gap: 0,
  },
  aside: {
    width: 300,
    minWidth: 240,
    borderRight: "1px solid #1e293b",
    padding: "20px 16px",
    overflowY: "auto",
  },
  sectionTitle: {
    fontSize: 14,
    fontWeight: 700,
    textTransform: "uppercase",
    letterSpacing: "0.08em",
    color: "#94a3b8",
    margin: "0 0 4px",
  },
  hint: {
    fontSize: 12,
    color: "#475569",
    margin: "0 0 12px",
  },
  residentList: {
    display: "flex",
    flexDirection: "column",
    gap: 8,
  },
  residentCard: {
    display: "flex",
    gap: 10,
    background: "#1e293b",
    border: "1px solid #334155",
    borderRadius: 10,
    padding: "10px 12px",
    cursor: "pointer",
    textAlign: "left",
    color: "inherit",
    width: "100%",
    transition: "border-color 0.15s",
  },
  residentCardSelected: {
    borderColor: "#3b82f6",
    background: "#1e3a5f",
  },
  residentAvatar: {
    fontSize: 28,
    lineHeight: 1,
  },
  residentInfo: {
    display: "flex",
    flexDirection: "column",
    gap: 2,
    minWidth: 0,
  },
  residentName: {
    fontSize: 14,
    fontWeight: 700,
  },
  residentHandle: {
    fontSize: 12,
    color: "#64748b",
  },
  residentDesc: {
    fontSize: 12,
    color: "#94a3b8",
    margin: "4px 0 0",
    lineHeight: 1.5,
  },
  memory: {
    fontSize: 11,
    color: "#a78bfa",
    margin: "4px 0 0",
    lineHeight: 1.5,
    fontStyle: "italic",
  },
  feed: {
    flex: 1,
    padding: "20px 24px",
    overflowY: "auto",
  },
  empty: {
    color: "#475569",
    fontSize: 14,
    marginTop: 32,
    textAlign: "center",
  },
  messageList: {
    display: "flex",
    flexDirection: "column",
    gap: 10,
    marginTop: 12,
  },
  messageCard: {
    background: "#1e293b",
    border: "1px solid #334155",
    borderRadius: 10,
    padding: "12px 16px",
  },
  messageHeader: {
    display: "flex",
    alignItems: "center",
    gap: 6,
    marginBottom: 8,
    flexWrap: "wrap",
  },
  messageAvatar: {
    fontSize: 16,
  },
  messageSender: {
    fontWeight: 700,
    fontSize: 13,
  },
  messageTo: {
    color: "#475569",
    fontSize: 13,
  },
  messageRecipient: {
    fontWeight: 700,
    fontSize: 13,
    color: "#94a3b8",
  },
  messageTime: {
    marginLeft: "auto",
    fontSize: 11,
    color: "#475569",
  },
  messageContent: {
    margin: 0,
    fontSize: 14,
    lineHeight: 1.6,
    color: "#cbd5e1",
  },
  footer: {
    display: "flex",
    alignItems: "center",
    gap: 12,
    padding: "12px 32px",
    borderTop: "1px solid #1e293b",
    flexWrap: "wrap",
  },
  footerTitle: {
    fontSize: 11,
    fontWeight: 700,
    textTransform: "uppercase",
    color: "#475569",
    letterSpacing: "0.08em",
  },
  footerCode: {
    fontSize: 11,
    color: "#64748b",
    background: "#1e293b",
    padding: "2px 6px",
    borderRadius: 4,
  },
};
