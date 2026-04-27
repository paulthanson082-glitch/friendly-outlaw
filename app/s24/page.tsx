"use client";

import React, { useEffect, useRef, useState } from "react";

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

interface Task {
  id: string;
  label: string;
  detail?: string;
  link?: string;
  linkLabel?: string;
}

interface Section {
  id: string;
  icon: string;
  title: string;
  color: string;
  tasks: Task[];
}

const SECTIONS: Section[] = [
  {
    id: "speed",
    icon: "⚡",
    title: "Speed & Performance",
    color: "#f59e0b",
    tasks: [
      {
        id: "speed-1",
        label: "Run Device Care optimizer",
        detail: "Settings → Device Care → Optimize Now — clears RAM and junk",
      },
      {
        id: "speed-2",
        label: "Enable RAM Plus (8 GB)",
        detail: "Settings → Device Care → Memory → RAM Plus",
      },
      {
        id: "speed-3",
        label: "Reduce animation scale to 0.5×",
        detail:
          "Settings → Developer Options → Window / Transition / Animator duration scale",
      },
      {
        id: "speed-4",
        label: "Enable Adaptive Battery",
        detail:
          "Settings → Battery → More battery settings → Adaptive battery",
      },
      {
        id: "speed-5",
        label: "Disable unused bloatware",
        detail: "Settings → Apps → sort by size → Disable apps you never use",
      },
      {
        id: "speed-6",
        label: "Install Good Lock for deeper tuning",
        detail: "Fine-tune One UI performance, lock screen, and quick panel",
        link: "https://play.google.com/store/search?q=good+lock+samsung&c=apps",
        linkLabel: "Play Store",
      },
      {
        id: "speed-7",
        label: "Set up Game Booster for heavy apps",
        detail:
          "Block background activity and calls during resource-heavy tasks",
      },
    ],
  },
  {
    id: "productivity",
    icon: "🚀",
    title: "Productivity",
    color: "#3b82f6",
    tasks: [
      {
        id: "prod-1",
        label: "Install Microsoft 365",
        detail: "Word, Excel, PowerPoint and PDF tools in one app",
        link: "https://play.google.com/store/apps/details?id=com.microsoft.office.officehubrow",
        linkLabel: "Play Store",
      },
      {
        id: "prod-2",
        label: "Set up Samsung Notes",
        detail: "Built-in — sync with Windows via Link to Windows",
      },
      {
        id: "prod-3",
        label: "Install Notion",
        detail: "All-in-one notes, tasks, wikis, and databases",
        link: "https://play.google.com/store/apps/details?id=notion.id",
        linkLabel: "Play Store",
      },
      {
        id: "prod-4",
        label: "Configure Bixby Routines",
        detail:
          "Settings → Advanced Features → Bixby Routines — automate daily triggers",
      },
      {
        id: "prod-5",
        label: "Enable Focus Mode",
        detail:
          "Settings → Digital Wellbeing → Focus Mode — block distracting apps",
      },
      {
        id: "prod-6",
        label: "Install Tasker (advanced automation)",
        detail: "Automate anything: Wi-Fi by location, DND at bedtime, etc.",
        link: "https://play.google.com/store/apps/details?id=net.dinglisch.android.taskerm",
        linkLabel: "Play Store",
      },
      {
        id: "prod-7",
        label: "Link to Windows for seamless PC sync",
        detail: "Settings → Connected Devices → Link to Windows",
      },
    ],
  },
  {
    id: "email",
    icon: "📧",
    title: "Email Management",
    color: "#10b981",
    tasks: [
      {
        id: "email-1",
        label: "Install Spark Mail for smart inbox",
        detail: "Prioritised inbox, snooze, and send-later scheduling",
        link: "https://play.google.com/store/apps/details?id=com.readdle.spark",
        linkLabel: "Play Store",
      },
      {
        id: "email-2",
        label: "Install Clean Email for bulk cleanup",
        detail: "Bulk unsubscribe, bundle similar emails, auto-clean rules",
        link: "https://play.google.com/store/apps/details?id=com.cleanemailapp.android",
        linkLabel: "Play Store",
      },
      {
        id: "email-3",
        label: "Enable spam filter in Gmail",
        detail:
          "Gmail settings → Filters and blocked addresses → create filters",
      },
      {
        id: "email-4",
        label: "Set up categories in Gmail",
        detail:
          "Gmail settings → Inbox → Inbox type: Default (tabs: Primary, Social, Promotions)",
      },
      {
        id: "email-5",
        label: "Unsubscribe from marketing emails",
        detail:
          "Use Clean Email or tap Unsubscribe in Gmail Promotions tab",
      },
      {
        id: "email-6",
        label: "Schedule email check times",
        detail:
          "Disable always-on email notifications; check at fixed times only",
      },
    ],
  },
  {
    id: "files",
    icon: "🗂️",
    title: "File Cleaning",
    color: "#8b5cf6",
    tasks: [
      {
        id: "files-1",
        label: "Run storage clean in Device Care",
        detail: "Settings → Device Care → Storage → Clean Now",
      },
      {
        id: "files-2",
        label: "Install Files by Google",
        detail:
          "Finds duplicates, large files, memes, junk APKs — free and fast",
        link: "https://play.google.com/store/apps/details?id=com.google.android.apps.nbu.files",
        linkLabel: "Play Store",
      },
      {
        id: "files-3",
        label: "Install SD Maid 2/SE for deep cleaning",
        detail: "Deep cache cleaning, app data analysis, duplicate finder",
        link: "https://play.google.com/store/apps/details?id=eu.darken.sdmse",
        linkLabel: "Play Store",
      },
      {
        id: "files-4",
        label: "Back up photos then free up space",
        detail:
          "Google Photos → Library → Manage storage → Free up space",
        link: "https://play.google.com/store/apps/details?id=com.google.android.apps.photos",
        linkLabel: "Play Store",
      },
      {
        id: "files-5",
        label: "Clear app caches in bulk",
        detail:
          "Settings → Apps → sort by size → select app → Storage → Clear cache",
      },
      {
        id: "files-6",
        label: "Delete downloaded files older than 30 days",
        detail: "My Files → Downloads → sort by date → select and delete",
      },
      {
        id: "files-7",
        label: "Schedule monthly storage review",
        detail: "Add a recurring reminder to repeat these file-cleaning tasks",
      },
    ],
  },
];

const STORAGE_KEY = "s24-tools-checked";

// ---------------------------------------------------------------------------
// Component
/**
 * Render the S24 Tools page: a multi-tab checklist for Speed & Performance, Productivity, Email Management, and File Cleaning with per-task toggles and per-section progress.
 *
 * The component persists task completion state to localStorage under STORAGE_KEY and provides controls to toggle individual tasks and reset the active section.
 *
 * @returns The React element for the S24 Tools page.
 */

export default function S24ToolsPage() {
  const [activeTab, setActiveTab] = useState<string>(SECTIONS[0].id);
  const [checked, setChecked] = useState<Record<string, boolean>>({});
  const hasLoaded = useRef(false);

  // Load saved state from localStorage
  useEffect(() => {
    try {
      const saved = localStorage.getItem(STORAGE_KEY);
      if (saved) {
        const parsed = JSON.parse(saved);
        if (
          parsed !== null &&
          typeof parsed === "object" &&
          !Array.isArray(parsed)
        ) {
          setChecked(parsed);
        }
      }
    } catch {
      // ignore parse errors
    }
    hasLoaded.current = true;
  }, []);

  // Persist state (only after initial load)
  useEffect(() => {
    if (!hasLoaded.current) return;
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(checked));
    } catch {
      // ignore storage errors
    }
  }, [checked]);

  const toggle = (id: string) =>
    setChecked((prev) => ({ ...prev, [id]: !prev[id] }));

  const resetSection = (sectionId: string) => {
    const section = SECTIONS.find((s) => s.id === sectionId);
    if (!section) return;
    setChecked((prev) => {
      const next = { ...prev };
      section.tasks.forEach((t) => {
        next[t.id] = false;
      });
      return next;
    });
  };

  const progressFor = (section: Section) => {
    const done = section.tasks.filter((t) => checked[t.id]).length;
    return { done, total: section.tasks.length };
  };

  const totalDone = SECTIONS.reduce(
    (sum, s) => sum + s.tasks.filter((t) => checked[t.id]).length,
    0
  );
  const totalTasks = SECTIONS.reduce((sum, s) => sum + s.tasks.length, 0);

  const activeSection = SECTIONS.find((s) => s.id === activeTab)!;
  const { done: activeDone, total: activeTotal } = progressFor(activeSection);

  return (
    <main style={s.main}>
      {/* Header */}
      <header style={s.header}>
        <div>
          <h1 style={s.title}>📱 S24 Tools</h1>
          <p style={s.subtitle}>
            Speed · Productivity · Email · File Cleaning
          </p>
        </div>
        <div style={s.overallBadge}>
          <span style={s.overallCount}>
            {totalDone}/{totalTasks}
          </span>
          <span style={s.overallLabel}>tasks done</span>
          <div style={s.overallBar}>
            <div
              style={{
                ...s.overallFill,
                width: `${(totalDone / totalTasks) * 100}%`,
              }}
            />
          </div>
        </div>
      </header>

      {/* Tabs */}
      <nav style={s.tabs}>
        {SECTIONS.map((sec) => {
          const { done, total } = progressFor(sec);
          const active = sec.id === activeTab;
          return (
            <button
              key={sec.id}
              onClick={() => setActiveTab(sec.id)}
              style={{
                ...s.tab,
                ...(active
                  ? { ...s.tabActive, borderBottomColor: sec.color }
                  : {}),
              }}
            >
              <span style={s.tabIcon}>{sec.icon}</span>
              <span style={s.tabLabel}>{sec.title}</span>
              <span
                style={{
                  ...s.tabBadge,
                  background: done === total ? "#15803d" : "#1e293b",
                }}
              >
                {done}/{total}
              </span>
            </button>
          );
        })}
      </nav>

      {/* Section content */}
      <section style={s.content}>
        {/* Section header */}
        <div style={s.sectionHeader}>
          <div>
            <h2 style={{ ...s.sectionTitle, color: activeSection.color }}>
              {activeSection.icon} {activeSection.title}
            </h2>
            <p style={s.sectionProgress}>
              {activeDone} of {activeTotal} tasks completed
            </p>
          </div>
          {activeDone > 0 && (
            <button
              style={s.resetBtn}
              onClick={() => resetSection(activeSection.id)}
            >
              Reset
            </button>
          )}
        </div>

        {/* Progress bar */}
        <div style={s.progressTrack}>
          <div
            style={{
              ...s.progressFill,
              width: `${(activeDone / activeTotal) * 100}%`,
              background: activeSection.color,
            }}
          />
        </div>

        {/* Task list */}
        <ul style={s.taskList}>
          {activeSection.tasks.map((task) => {
            const done = !!checked[task.id];
            return (
              <li key={task.id} style={s.taskItem}>
                <button
                  style={{
                    ...s.checkbox,
                    ...(done
                      ? {
                          background: activeSection.color,
                          borderColor: activeSection.color,
                        }
                      : {}),
                  }}
                  onClick={() => toggle(task.id)}
                  aria-label={done ? 'Mark incomplete' : 'Mark complete'}
                  aria-pressed={done}
                >
                  {done && <span style={s.checkmark}>✓</span>}
                </button>
                <div style={s.taskBody}>
                  <p
                    style={{
                      ...s.taskLabel,
                      ...(done ? s.taskLabelDone : {}),
                    }}
                  >
                    {task.label}
                  </p>
                  {task.detail && (
                    <p style={s.taskDetail}>{task.detail}</p>
                  )}
                  {task.link && (
                    <a
                      href={task.link}
                      target="_blank"
                      rel="noopener noreferrer"
                      style={s.taskLink}
                    >
                      {task.linkLabel ?? "Open"} →
                    </a>
                  )}
                </div>
              </li>
            );
          })}
        </ul>
      </section>

      <footer style={s.footer}>
        <p style={s.footerText}>
          Tap any task to mark it done. Progress is saved automatically on your
          device.
        </p>
      </footer>
    </main>
  );
}

// ---------------------------------------------------------------------------
// Styles
// ---------------------------------------------------------------------------

const s: Record<string, React.CSSProperties> = {
  main: {
    minHeight: "100vh",
    background: "#0f172a",
    color: "#e2e8f0",
    fontFamily: "'Segoe UI', system-ui, sans-serif",
    display: "flex",
    flexDirection: "column",
    maxWidth: 720,
    margin: "0 auto",
  },
  header: {
    display: "flex",
    justifyContent: "space-between",
    alignItems: "center",
    padding: "24px 20px 16px",
    borderBottom: "1px solid #1e293b",
    gap: 12,
    flexWrap: "wrap",
  },
  title: {
    fontSize: 26,
    fontWeight: 800,
    margin: 0,
    color: "#f1f5f9",
  },
  subtitle: {
    margin: "4px 0 0",
    fontSize: 13,
    color: "#64748b",
  },
  overallBadge: {
    display: "flex",
    flexDirection: "column",
    alignItems: "flex-end",
    gap: 4,
    minWidth: 100,
  },
  overallCount: {
    fontSize: 22,
    fontWeight: 800,
    color: "#f1f5f9",
    lineHeight: 1,
  },
  overallLabel: {
    fontSize: 11,
    color: "#64748b",
    marginTop: -2,
  },
  overallBar: {
    width: 100,
    height: 4,
    background: "#1e293b",
    borderRadius: 99,
    overflow: "hidden",
  },
  overallFill: {
    height: "100%",
    background: "linear-gradient(90deg, #3b82f6, #8b5cf6)",
    borderRadius: 99,
    transition: "width 0.3s ease",
  },
  tabs: {
    display: "flex",
    overflowX: "auto",
    borderBottom: "1px solid #1e293b",
    scrollbarWidth: "none",
  },
  tab: {
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    gap: 4,
    padding: "12px 16px",
    background: "none",
    border: "none",
    borderBottom: "2px solid transparent",
    color: "#64748b",
    cursor: "pointer",
    whiteSpace: "nowrap",
    minWidth: 100,
    transition: "color 0.15s",
  },
  tabActive: {
    color: "#f1f5f9",
    borderBottom: "2px solid",
  },
  tabIcon: {
    fontSize: 20,
  },
  tabLabel: {
    fontSize: 11,
    fontWeight: 600,
    textTransform: "uppercase",
    letterSpacing: "0.05em",
  },
  tabBadge: {
    fontSize: 10,
    fontWeight: 700,
    padding: "1px 6px",
    borderRadius: 99,
    color: "#94a3b8",
  },
  content: {
    flex: 1,
    padding: "20px",
  },
  sectionHeader: {
    display: "flex",
    justifyContent: "space-between",
    alignItems: "flex-start",
    marginBottom: 12,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 700,
    margin: 0,
  },
  sectionProgress: {
    fontSize: 12,
    color: "#64748b",
    margin: "4px 0 0",
  },
  resetBtn: {
    background: "none",
    border: "1px solid #334155",
    color: "#94a3b8",
    borderRadius: 6,
    padding: "4px 10px",
    fontSize: 12,
    cursor: "pointer",
  },
  progressTrack: {
    width: "100%",
    height: 6,
    background: "#1e293b",
    borderRadius: 99,
    overflow: "hidden",
    marginBottom: 20,
  },
  progressFill: {
    height: "100%",
    borderRadius: 99,
    transition: "width 0.3s ease",
  },
  taskList: {
    listStyle: "none",
    margin: 0,
    padding: 0,
    display: "flex",
    flexDirection: "column",
    gap: 10,
  },
  taskItem: {
    display: "flex",
    gap: 12,
    background: "#1e293b",
    border: "1px solid #334155",
    borderRadius: 12,
    padding: "14px 16px",
    alignItems: "flex-start",
  },
  checkbox: {
    width: 24,
    height: 24,
    minWidth: 24,
    borderRadius: 6,
    border: "2px solid #475569",
    background: "transparent",
    cursor: "pointer",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    marginTop: 1,
    transition: "background 0.15s, border-color 0.15s",
  },
  checkmark: {
    color: "#fff",
    fontSize: 13,
    fontWeight: 800,
    lineHeight: 1,
  },
  taskBody: {
    flex: 1,
    minWidth: 0,
  },
  taskLabel: {
    margin: 0,
    fontSize: 15,
    fontWeight: 600,
    color: "#f1f5f9",
    lineHeight: 1.4,
  },
  taskLabelDone: {
    textDecoration: "line-through",
    color: "#475569",
  },
  taskDetail: {
    margin: "4px 0 0",
    fontSize: 12,
    color: "#64748b",
    lineHeight: 1.5,
  },
  taskLink: {
    display: "inline-block",
    marginTop: 6,
    fontSize: 12,
    color: "#3b82f6",
    textDecoration: "none",
    fontWeight: 600,
  },
  footer: {
    padding: "16px 20px",
    borderTop: "1px solid #1e293b",
  },
  footerText: {
    margin: 0,
    fontSize: 12,
    color: "#475569",
    textAlign: "center",
  },
};
