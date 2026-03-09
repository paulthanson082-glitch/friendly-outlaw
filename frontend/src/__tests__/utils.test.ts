/**
 * Utility tests for the Jules frontend application.
 * These tests cover pure utility logic that doesn't require DOM or API access.
 */

// --- Word count utility (mirrors backend logic) ---
function countWords(text: string): number {
  return text.split(/\s+/).filter((w) => w.length > 0).length;
}

describe('countWords', () => {
  it('counts words in a simple sentence', () => {
    expect(countWords('Hello world')).toBe(2);
  });

  it('handles multiple spaces', () => {
    expect(countWords('  hello   world  ')).toBe(2);
  });

  it('returns 0 for empty string', () => {
    expect(countWords('')).toBe(0);
  });

  it('returns 0 for whitespace only', () => {
    expect(countWords('   ')).toBe(0);
  });

  it('counts single word', () => {
    expect(countWords('Jules')).toBe(1);
  });

  it('counts a longer passage', () => {
    const text = 'The quick brown fox jumps over the lazy dog';
    expect(countWords(text)).toBe(9);
  });
});

// --- Template placeholder replacement ---
function fillTemplate(template: string, values: Record<string, string>): string {
  let result = template;
  for (const [key, value] of Object.entries(values)) {
    result = result.replaceAll(`{{${key}}}`, value);
  }
  return result;
}

describe('fillTemplate', () => {
  it('replaces a single placeholder', () => {
    const result = fillTemplate('Hello, {{name}}!', { name: 'Jules' });
    expect(result).toBe('Hello, Jules!');
  });

  it('replaces multiple placeholders', () => {
    const result = fillTemplate('{{greeting}}, {{name}}!', {
      greeting: 'Hi',
      name: 'writer',
    });
    expect(result).toBe('Hi, writer!');
  });

  it('replaces repeated placeholder', () => {
    const result = fillTemplate('{{word}} and {{word}}', { word: 'test' });
    expect(result).toBe('test and test');
  });

  it('leaves unknown placeholders intact', () => {
    const result = fillTemplate('Hello {{unknown}}', {});
    expect(result).toBe('Hello {{unknown}}');
  });

  it('returns template unchanged when values is empty', () => {
    const template = 'No placeholders here';
    expect(fillTemplate(template, {})).toBe(template);
  });
});

// --- Reading time estimation ---
function estimateReadingTime(wordCount: number, wordsPerMinute: number = 200): number {
  return Math.ceil(wordCount / wordsPerMinute);
}

describe('estimateReadingTime', () => {
  it('calculates reading time correctly', () => {
    expect(estimateReadingTime(200)).toBe(1);
    expect(estimateReadingTime(400)).toBe(2);
  });

  it('rounds up for partial minutes', () => {
    expect(estimateReadingTime(201)).toBe(2);
    expect(estimateReadingTime(1)).toBe(1);
  });

  it('returns 0 for empty text', () => {
    expect(estimateReadingTime(0)).toBe(0);
  });

  it('respects custom words per minute', () => {
    expect(estimateReadingTime(300, 300)).toBe(1);
    expect(estimateReadingTime(600, 300)).toBe(2);
  });
});

// --- Kanban column ordering ---
const KANBAN_COLUMNS = ['backlog', 'planning', 'running', 'review', 'done'] as const;
type KanbanColumn = (typeof KANBAN_COLUMNS)[number];

function nextColumn(col: KanbanColumn): KanbanColumn | null {
  const idx = KANBAN_COLUMNS.indexOf(col);
  if (idx === -1 || idx === KANBAN_COLUMNS.length - 1) return null;
  return KANBAN_COLUMNS[idx + 1];
}

function prevColumn(col: KanbanColumn): KanbanColumn | null {
  const idx = KANBAN_COLUMNS.indexOf(col);
  if (idx <= 0) return null;
  return KANBAN_COLUMNS[idx - 1];
}

describe('Kanban column navigation', () => {
  it('advances from backlog to planning', () => {
    expect(nextColumn('backlog')).toBe('planning');
  });

  it('advances through the full pipeline', () => {
    expect(nextColumn('planning')).toBe('running');
    expect(nextColumn('running')).toBe('review');
    expect(nextColumn('review')).toBe('done');
  });

  it('returns null when already at done', () => {
    expect(nextColumn('done')).toBeNull();
  });

  it('regresses from done to review', () => {
    expect(prevColumn('done')).toBe('review');
  });

  it('returns null when already at backlog', () => {
    expect(prevColumn('backlog')).toBeNull();
  });
});

// --- HTML escaping ---
function escapeHtml(text: string): string {
  const map: Record<string, string> = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#039;',
  };
  return text.replace(/[&<>"']/g, (char) => map[char]);
}

describe('escapeHtml', () => {
  it('escapes ampersands', () => {
    expect(escapeHtml('Tom & Jerry')).toBe('Tom &amp; Jerry');
  });

  it('escapes angle brackets', () => {
    expect(escapeHtml('<script>')).toBe('&lt;script&gt;');
  });

  it('escapes quotes', () => {
    expect(escapeHtml('"hello"')).toBe('&quot;hello&quot;');
    expect(escapeHtml("it's")).toBe('it&#039;s');
  });

  it('leaves safe characters unchanged', () => {
    expect(escapeHtml('Hello World 123')).toBe('Hello World 123');
  });

  it('handles empty string', () => {
    expect(escapeHtml('')).toBe('');
  });
});
