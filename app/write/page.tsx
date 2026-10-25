"use client";

import { useState } from "react";
const APP_NAME = "Hanson's Writing Assistant";

// Text glyph icons keep this page free of an extra icon dependency.
const glyph = (g: string) =>
  function Glyph({ className }: { className?: string }) {
    return (
      <span aria-hidden className={`inline-block leading-none ${className ?? ""}`}>
        {g}
      </span>
    );
  };
const BookOpen = glyph("📖");
const FileText = glyph("📄");
const Sparkles = glyph("✦");
const ChevronRight = glyph("›");
const Check = glyph("✓");
const RefreshCw = glyph("↻");
const Plus = glyph("+");
const Wand2 = glyph("✎");

type Section = { id: string; title: string; prompt: string; content?: string };
type Template = {
  id: string;
  name: string;
  category: string;
  description: string;
  color: string;
  icon: string;
  sections: Section[];
};
type Draft = {
  id: number;
  title: string;
  templateName: string;
  category: string;
  icon: string;
  sections: Section[];
  created: string;
};
type PolishStyle = { id: string; name: string; desc: string; icon: string; instruction: string };
type View = "templates" | "draft" | "polish";

const TEMPLATES: Template[] = [
  {
    id: "case_study", name: "Case Study", category: "Counseling",
    description: "Client case study documentation",
    color: "bg-green-100 text-green-700 border-green-200", icon: "🧠",
    sections: [
      { id: "bg", title: "Client Background", prompt: "Describe age, demographics, and presenting issues..." },
      { id: "assess", title: "Assessment", prompt: "Initial evaluation and diagnosis..." },
      { id: "plan", title: "Treatment Plan", prompt: "Goals and therapeutic approach..." },
      { id: "progress", title: "Progress Notes", prompt: "Session summaries and progress..." },
      { id: "outcome", title: "Outcome", prompt: "Results and recommendations..." },
    ],
  },
  {
    id: "reflection", name: "Reflection Journal", category: "Counseling",
    description: "Personal reflection on counseling practice",
    color: "bg-teal-100 text-teal-700 border-teal-200", icon: "📔",
    sections: [
      { id: "exp", title: "Experience", prompt: "Describe what happened in the session..." },
      { id: "feel", title: "Feelings", prompt: "Your emotional response..." },
      { id: "analysis", title: "Analysis", prompt: "What worked well? What could improve?" },
      { id: "learn", title: "Learning", prompt: "Key insights and takeaways..." },
      { id: "action", title: "Action Plan", prompt: "How will you apply this learning?" },
    ],
  },
  {
    id: "research_paper", name: "Research Paper", category: "Academic",
    description: "Full academic research paper structure",
    color: "bg-blue-100 text-blue-700 border-blue-200", icon: "🎓",
    sections: [
      { id: "abs", title: "Abstract", prompt: "Summarize your research in 150-250 words..." },
      { id: "intro", title: "Introduction", prompt: "Introduce your topic and research question..." },
      { id: "lit", title: "Literature Review", prompt: "Review existing research on this topic..." },
      { id: "method", title: "Methodology", prompt: "Explain your research methods..." },
      { id: "results", title: "Results", prompt: "Present your findings..." },
      { id: "disc", title: "Discussion", prompt: "Analyze and interpret your results..." },
      { id: "conc", title: "Conclusion", prompt: "Summarize key findings and implications..." },
    ],
  },
  {
    id: "essay", name: "Essay", category: "Academic",
    description: "Standard 5-paragraph essay structure",
    color: "bg-indigo-100 text-indigo-700 border-indigo-200", icon: "📝",
    sections: [
      { id: "intro", title: "Introduction", prompt: "Hook, background, and thesis statement..." },
      { id: "body1", title: "Body Paragraph 1", prompt: "First main point with evidence..." },
      { id: "body2", title: "Body Paragraph 2", prompt: "Second main point with evidence..." },
      { id: "body3", title: "Body Paragraph 3", prompt: "Third main point with evidence..." },
      { id: "conc", title: "Conclusion", prompt: "Restate thesis and summarize key points..." },
    ],
  },
  {
    id: "personal_statement", name: "Personal Statement", category: "Personal",
    description: "Application or biography statement",
    color: "bg-orange-100 text-orange-700 border-orange-200", icon: "🙋",
    sections: [
      { id: "hook", title: "Opening Hook", prompt: "Compelling opening that captures attention..." },
      { id: "bg", title: "Background", prompt: "Your story and journey..." },
      { id: "achieve", title: "Achievements", prompt: "Key accomplishments and experiences..." },
      { id: "goals", title: "Goals", prompt: "Future aspirations and how this fits..." },
      { id: "close", title: "Conclusion", prompt: "Strong closing that leaves an impression..." },
    ],
  },
  {
    id: "short_story", name: "Short Story", category: "Creative",
    description: "Fiction story with full narrative arc",
    color: "bg-purple-100 text-purple-700 border-purple-200", icon: "✨",
    sections: [
      { id: "open", title: "Opening", prompt: "Set the scene and introduce your character..." },
      { id: "incident", title: "Inciting Incident", prompt: "What disrupts the normal world?" },
      { id: "rising", title: "Rising Action", prompt: "Build tension and conflict..." },
      { id: "climax", title: "Climax", prompt: "The peak moment of tension..." },
      { id: "resolution", title: "Resolution", prompt: "How is the conflict resolved?" },
    ],
  },
];

const CATEGORIES = ["All", "Counseling", "Academic", "Personal", "Creative"];
const ASSIST_TYPES = ["Expand", "Improve", "Summarize", "Rephrase"];

const POLISH_STYLES: PolishStyle[] = [
  {
    id: "academic", name: "Academic Polish", icon: "🎓",
    desc: "Formal language, stronger thesis, clear structure markers",
    instruction:
      "Transform for academic submission: use formal vocabulary, avoid contractions, strengthen the thesis, add transitions like 'Furthermore' and 'Consequently', and use academic phrasing like 'Research indicates'.",
  },
  {
    id: "conversational", name: "Conversational Polish", icon: "💬",
    desc: "Warmer tone, direct address, accessible phrasing",
    instruction:
      "Transform for conversational sharing: use friendly, approachable language, include 'you' and 'we', replace jargon with everyday words, and use natural transitions.",
  },
  {
    id: "presentation", name: "Presentation Polish", icon: "🎤",
    desc: "Short sentences, rhythm and cadence, memorable phrases",
    instruction:
      "Transform for oral presentation: keep sentences to 15-20 words, create rhythm and cadence, craft memorable quotable phrases, use spoken transitions, and prefer active voice.",
  },
];

function wordCount(text: string) {
  return text.trim() ? text.trim().split(/\s+/).length : 0;
}

async function callClaude(prompt: string): Promise<string> {
  const res = await fetch("/api/claude", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ prompt }),
  });
  const data = await res.json();
  if (!res.ok) throw new Error(data.error || "Request failed");
  return data.result as string;
}

function Header({ view, setView, draftCount }: { view: View; setView: (v: View) => void; draftCount: number }) {
  const tab = (id: View, label: string) => (
    <button
      onClick={() => setView(id)}
      className={`px-4 py-1.5 rounded-lg text-sm font-medium ${
        view === id ? "bg-blue-600 text-white" : "bg-gray-100 text-gray-700 hover:bg-gray-200"
      }`}
    >
      {label}
    </button>
  );
  return (
    <header className="bg-white border-b px-6 py-4 flex items-center justify-between">
      <div className="flex items-center gap-3">
        <BookOpen className="text-2xl" />
        <h1 className="text-xl font-bold text-gray-900">{APP_NAME}</h1>
      </div>
      <div className="flex gap-3">
        {tab("templates", "Templates")}
        {tab("draft", draftCount > 0 ? `Draft (${draftCount})` : "Draft")}
        {tab("polish", "Polish")}
      </div>
    </header>
  );
}

export default function WritingApp() {
  const [view, setView] = useState<View>("templates");
  const [categoryFilter, setCategoryFilter] = useState("All");
  const [drafts, setDrafts] = useState<Draft[]>([]);
  const [currentDraft, setCurrentDraft] = useState<Draft | null>(null);
  const [activeSection, setActiveSection] = useState(0);
  const [aiLoading, setAiLoading] = useState(false);
  const [aiSuggestion, setAiSuggestion] = useState("");
  const [polishStyle, setPolishStyle] = useState<PolishStyle | null>(null);
  const [polishResult, setPolishResult] = useState("");
  const [polishLoading, setPolishLoading] = useState(false);

  const filteredTemplates = TEMPLATES.filter((t) => categoryFilter === "All" || t.category === categoryFilter);

  function saveDraft(updated: Draft) {
    setCurrentDraft(updated);
    setDrafts((prev) => prev.map((d) => (d.id === updated.id ? updated : d)));
  }

  function createDraft(template: Template) {
    const draft: Draft = {
      id: Date.now(),
      title: `Untitled ${template.name}`,
      templateName: template.name,
      category: template.category,
      icon: template.icon,
      sections: template.sections.map((s) => ({ ...s, content: "" })),
      created: new Date().toLocaleDateString(),
    };
    setDrafts((prev) => [draft, ...prev]);
    setCurrentDraft(draft);
    setActiveSection(0);
    setAiSuggestion("");
    setPolishResult("");
    setView("draft");
  }

  function updateSection(idx: number, content: string) {
    if (!currentDraft) return;
    saveDraft({
      ...currentDraft,
      sections: currentDraft.sections.map((s, i) => (i === idx ? { ...s, content } : s)),
    });
  }

  function totalWords() {
    return currentDraft?.sections.reduce((acc, s) => acc + wordCount(s.content || ""), 0) || 0;
  }

  async function aiAssist(assistType: string) {
    if (!currentDraft) return;
    const section = currentDraft.sections[activeSection];
    setAiLoading(true);
    setAiSuggestion("");
    const task: Record<string, string> = {
      Expand: "Expand with more detail and examples. If empty, generate content based on the section prompt.",
      Improve: "Improve clarity, flow, and quality.",
      Summarize: "Summarize into concise key points.",
      Rephrase: "Rephrase using different words while keeping the same meaning.",
    };
    try {
      const result = await callClaude(
        `Template: ${currentDraft.templateName} (${currentDraft.category})
Section: ${section.title}
Prompt: ${section.prompt}
Current content: ${section.content || "[empty]"}

Task: ${task[assistType]}

Return only the content, no preamble or explanation.`
      );
      setAiSuggestion(result);
    } catch {
      setAiSuggestion("Could not reach the AI. Check that ANTHROPIC_API_KEY is set on the server.");
    }
    setAiLoading(false);
  }

  function applyAI(replace: boolean) {
    if (!currentDraft) return;
    const existing = currentDraft.sections[activeSection].content || "";
    updateSection(activeSection, replace || !existing ? aiSuggestion : `${existing}\n\n${aiSuggestion}`);
    setAiSuggestion("");
  }

  async function polishDocument(style: PolishStyle) {
    if (!currentDraft) return;
    setPolishLoading(true);
    setPolishResult("");
    try {
      const fullDoc = currentDraft.sections
        .filter((s) => s.content)
        .map((s) => `## ${s.title}\n\n${s.content}`)
        .join("\n\n");
      const result = await callClaude(
        `${style.instruction}

DOCUMENT TO TRANSFORM:
# ${currentDraft.title}

${fullDoc}

Return ONLY the transformed document with ## section headers. No preamble.`
      );
      setPolishResult(result);
    } catch {
      setPolishResult("Could not reach the AI. Check that ANTHROPIC_API_KEY is set on the server.");
    }
    setPolishLoading(false);
  }

  const shell = (children: React.ReactNode) => (
    <div className="min-h-screen bg-gray-50">
      <Header view={view} setView={setView} draftCount={drafts.length} />
      {children}
    </div>
  );

  // Templates
  if (view === "templates")
    return shell(
      <div className="max-w-5xl mx-auto px-6 py-8">
        <h2 className="text-2xl font-bold text-gray-900 mb-1">Choose a Template</h2>
        <p className="text-gray-500 mb-6 text-sm">Pick a template to start writing with AI assistance</p>

        <div className="flex gap-2 mb-6 flex-wrap">
          {CATEGORIES.map((cat) => (
            <button
              key={cat}
              onClick={() => setCategoryFilter(cat)}
              className={`px-4 py-1.5 rounded-full text-sm font-medium border transition-colors ${
                categoryFilter === cat
                  ? "bg-blue-600 text-white border-blue-600"
                  : "bg-white text-gray-600 border-gray-200 hover:border-blue-300"
              }`}
            >
              {cat}
            </button>
          ))}
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {filteredTemplates.map((t) => (
            <div
              key={t.id}
              className="bg-white rounded-xl border border-gray-200 p-5 hover:shadow-md transition-shadow cursor-pointer group"
              onClick={() => createDraft(t)}
            >
              <div className="flex items-start justify-between mb-3">
                <span className="text-3xl">{t.icon}</span>
                <span className={`text-xs font-medium px-2 py-1 rounded-full border ${t.color}`}>{t.category}</span>
              </div>
              <h3 className="font-semibold text-gray-900 mb-1">{t.name}</h3>
              <p className="text-sm text-gray-500 mb-3">{t.description}</p>
              <div className="flex items-center justify-between">
                <span className="text-xs text-gray-400">{t.sections.length} sections</span>
                <span className="text-blue-600 text-sm font-medium flex items-center gap-1 group-hover:gap-2 transition-all">
                  Start <ChevronRight className="w-4 h-4" />
                </span>
              </div>
            </div>
          ))}
        </div>

        {drafts.length > 0 && (
          <div className="mt-10">
            <h3 className="text-lg font-semibold text-gray-800 mb-3">Recent Drafts</h3>
            <div className="space-y-2">
              {drafts.slice(0, 3).map((d) => (
                <div
                  key={d.id}
                  className="bg-white rounded-lg border border-gray-200 px-4 py-3 flex items-center justify-between hover:shadow-sm cursor-pointer"
                  onClick={() => {
                    setCurrentDraft(d);
                    setActiveSection(0);
                    setAiSuggestion("");
                    setView("draft");
                  }}
                >
                  <div className="flex items-center gap-3">
                    <span className="text-xl">{d.icon}</span>
                    <div>
                      <p className="font-medium text-gray-900 text-sm">{d.title}</p>
                      <p className="text-xs text-gray-400">
                        {d.templateName} · {d.created}
                      </p>
                    </div>
                  </div>
                  <ChevronRight className="w-4 h-4 text-gray-400" />
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    );

  // Draft
  if (view === "draft") {
    if (!currentDraft)
      return shell(
        <div className="flex flex-col items-center justify-center h-96 text-center p-8">
          <FileText className="text-6xl text-gray-300 mb-4" />
          <h2 className="text-xl font-semibold text-gray-700 mb-2">No Draft Open</h2>
          <p className="text-gray-500 mb-6">Start from a template or open an existing draft</p>
          <button
            onClick={() => setView("templates")}
            className="px-5 py-2 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700"
          >
            Browse Templates
          </button>
        </div>
      );

    const section = currentDraft.sections[activeSection];
    return shell(
      <div className="flex h-[calc(100vh-65px)]">
        <div className="w-56 bg-white border-r flex flex-col">
          <div className="p-4 border-b">
            <div className="flex items-center gap-2 mb-1">
              <span className="text-lg">{currentDraft.icon}</span>
              <input
                className="text-sm font-semibold text-gray-800 w-full bg-transparent outline-none"
                value={currentDraft.title}
                onChange={(e) => saveDraft({ ...currentDraft, title: e.target.value })}
              />
            </div>
            <p className="text-xs text-gray-400">{totalWords()} words total</p>
          </div>
          <div className="flex-1 overflow-y-auto p-2">
            {currentDraft.sections.map((s, i) => (
              <button
                key={s.id}
                onClick={() => {
                  setActiveSection(i);
                  setAiSuggestion("");
                }}
                className={`w-full text-left px-3 py-2 rounded-lg mb-1 text-sm transition-colors ${
                  activeSection === i ? "bg-blue-50 text-blue-700 font-medium" : "text-gray-600 hover:bg-gray-50"
                }`}
              >
                <div className="truncate">{s.title}</div>
                <div className="text-xs opacity-60">{wordCount(s.content || "")} words</div>
              </button>
            ))}
          </div>
          <div className="p-3 border-t">
            <button
              onClick={() => {
                setPolishResult("");
                setView("polish");
              }}
              className="w-full py-2 bg-purple-600 text-white text-sm font-medium rounded-lg hover:bg-purple-700 flex items-center justify-center gap-2"
            >
              <Sparkles className="w-4 h-4" /> Polish
            </button>
          </div>
        </div>

        <div className="flex-1 flex flex-col overflow-hidden">
          {currentDraft.category === "Counseling" && (
            <div className="bg-amber-50 border-b border-amber-200 px-6 py-2 text-xs text-amber-800">
              Privacy: AI Assist and Polish send your text to a cloud API. Do not enter names or identifying details
              about clients. Use initials or a pseudonym.
            </div>
          )}
          <div className="bg-white border-b px-6 py-3">
            <h2 className="font-semibold text-gray-800">{section.title}</h2>
            <p className="text-xs text-gray-400 italic">{section.prompt}</p>
          </div>

          <div className="bg-white border-b px-6 py-2 flex items-center gap-2 flex-wrap">
            <span className="text-xs text-gray-500 font-medium mr-1">AI:</span>
            {ASSIST_TYPES.map((type) => (
              <button
                key={type}
                onClick={() => aiAssist(type)}
                disabled={aiLoading}
                className="px-3 py-1 text-xs font-medium rounded-full bg-purple-50 text-purple-700 border border-purple-200 hover:bg-purple-100 disabled:opacity-50 flex items-center gap-1"
              >
                <Wand2 className="w-3 h-3" /> {type}
              </button>
            ))}
            {aiLoading && <span className="text-xs text-purple-500 animate-pulse">Generating...</span>}
          </div>

          <div className="flex-1 overflow-y-auto p-6">
            <textarea
              className="w-full h-64 p-4 text-sm text-gray-800 border border-gray-200 rounded-xl resize-none focus:outline-none focus:ring-2 focus:ring-blue-300 leading-relaxed"
              placeholder={section.prompt}
              value={section.content || ""}
              onChange={(e) => updateSection(activeSection, e.target.value)}
            />
            <p className="text-xs text-gray-400 mt-1 text-right">{wordCount(section.content || "")} words</p>

            {aiSuggestion && (
              <div className="mt-4 rounded-xl border border-purple-200 bg-purple-50 p-4">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-xs font-semibold text-purple-700 flex items-center gap-1">
                    <Sparkles className="w-3 h-3" /> AI Suggestion
                  </span>
                  <button onClick={() => setAiSuggestion("")} className="text-xs text-gray-400 hover:text-gray-600">
                    dismiss
                  </button>
                </div>
                <p className="text-sm text-gray-700 whitespace-pre-wrap leading-relaxed mb-3">{aiSuggestion}</p>
                <div className="flex gap-2">
                  <button
                    onClick={() => applyAI(true)}
                    className="px-3 py-1.5 bg-purple-600 text-white text-xs font-medium rounded-lg hover:bg-purple-700 flex items-center gap-1"
                  >
                    <RefreshCw className="w-3 h-3" /> Replace
                  </button>
                  <button
                    onClick={() => applyAI(false)}
                    className="px-3 py-1.5 bg-white border border-purple-300 text-purple-700 text-xs font-medium rounded-lg hover:bg-purple-50 flex items-center gap-1"
                  >
                    <Plus className="w-3 h-3" /> Append
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    );
  }

  // Polish
  if (!currentDraft)
    return shell(
      <div className="flex flex-col items-center justify-center h-96 text-center p-8">
        <Sparkles className="text-6xl text-gray-300 mb-4" />
        <h2 className="text-xl font-semibold text-gray-700 mb-2">No Draft to Polish</h2>
        <p className="text-gray-500 mb-6">Create a draft first, then come back to polish it</p>
        <button
          onClick={() => setView("templates")}
          className="px-5 py-2 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700"
        >
          Browse Templates
        </button>
      </div>
    );

  return shell(
    <div className="max-w-4xl mx-auto px-6 py-8">
      <div className="flex items-center gap-3 mb-2">
        <span className="text-2xl">{currentDraft.icon}</span>
        <h2 className="text-2xl font-bold text-gray-900">{currentDraft.title}</h2>
      </div>
      <p className="text-sm text-gray-500 mb-8">
        {totalWords()} words · {currentDraft.sections.filter((s) => s.content).length} of{" "}
        {currentDraft.sections.length} sections written
      </p>

      <h3 className="text-lg font-semibold text-gray-800 mb-4">Choose a Polish Style</h3>
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-8">
        {POLISH_STYLES.map((style) => (
          <button
            key={style.id}
            onClick={() => setPolishStyle(style)}
            className={`rounded-xl border-2 p-5 text-left transition-all ${
              polishStyle?.id === style.id ? "border-blue-500 bg-blue-50" : "border-gray-200 bg-white hover:border-blue-300"
            }`}
          >
            <div className="text-3xl mb-3">{style.icon}</div>
            <h4 className="font-semibold text-gray-900 mb-1">{style.name}</h4>
            <p className="text-xs text-gray-500">{style.desc}</p>
            {polishStyle?.id === style.id && (
              <div className="mt-3 flex items-center gap-1 text-blue-600 text-xs font-medium">
                <Check className="w-3 h-3" /> Selected
              </div>
            )}
          </button>
        ))}
      </div>

      <button
        onClick={() => polishStyle && polishDocument(polishStyle)}
        disabled={!polishStyle || polishLoading}
        className="w-full py-3 rounded-xl font-semibold text-white text-sm flex items-center justify-center gap-2 mb-8 transition-all disabled:opacity-50 disabled:cursor-not-allowed bg-purple-600 hover:bg-purple-700"
      >
        {polishLoading ? (
          "Polishing document..."
        ) : (
          <>
            <Sparkles className="w-4 h-4" /> Polish with {polishStyle?.name || "AI"}
          </>
        )}
      </button>

      {polishResult ? (
        <div className="bg-white rounded-xl border border-purple-200 p-6">
          <h3 className="font-semibold text-purple-700 flex items-center gap-2 mb-4">
            <Sparkles className="w-4 h-4" /> Polished Document: {polishStyle?.name}
          </h3>
          <div className="text-gray-700 whitespace-pre-wrap leading-relaxed text-sm border-t pt-4">{polishResult}</div>
        </div>
      ) : (
        <div>
          <h3 className="text-lg font-semibold text-gray-800 mb-4">Current Draft</h3>
          <div className="space-y-4">
            {currentDraft.sections.map((s, i) => (
              <div key={s.id} className="bg-white rounded-xl border border-gray-200 p-5">
                <div className="flex items-center justify-between mb-2">
                  <h4 className="font-semibold text-gray-800">{s.title}</h4>
                  <span className="text-xs text-gray-400">{wordCount(s.content || "")} words</span>
                </div>
                {s.content ? (
                  <p className="text-sm text-gray-600 leading-relaxed line-clamp-3">{s.content}</p>
                ) : (
                  <p className="text-sm text-gray-300 italic">{s.prompt}</p>
                )}
                <button
                  onClick={() => {
                    setActiveSection(i);
                    setView("draft");
                  }}
                  className="mt-3 text-xs text-blue-600 hover:text-blue-700 font-medium flex items-center gap-1"
                >
                  {s.content ? "Edit section" : "Write section"} <ChevronRight className="w-3 h-3" />
                </button>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
