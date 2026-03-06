import { v4 as uuidv4 } from 'uuid';
import { getDatabase } from '../db/connection.js';

export interface Placeholder {
  key: string;
  description: string;
  example?: string;
}

export interface Template {
  id: string;
  userId?: string;
  name: string;
  category: string;
  description: string;
  content: string;
  placeholders: Placeholder[];
  isDefault: boolean;
  createdAt: string;
  modifiedAt: string;
}

const DEFAULT_TEMPLATES = [
  {
    name: 'Short Story',
    category: 'shortStory',
    description: 'Template for writing short stories',
    content: `# {{story_title}}

## Setting
{{setting_description}}

## Characters
{{character_list}}

## Plot
{{plot_summary}}

## Story

{{story_content}}

## Conclusion
{{conclusion}}`,
    placeholders: [
      { key: 'story_title', description: 'Title of the short story' },
      { key: 'setting_description', description: 'Where and when the story takes place' },
      { key: 'character_list', description: 'List of main characters' },
      { key: 'plot_summary', description: 'Brief summary of what happens' },
      { key: 'story_content', description: 'The main story content' },
      { key: 'conclusion', description: 'How the story ends' },
    ],
  },
  {
    name: 'Blog Post',
    category: 'blogPost',
    description: 'Template for writing blog posts',
    content: `# {{post_title}}

**Published:** {{publication_date}}
**Author:** {{author_name}}

## Introduction
{{intro_paragraph}}

## Main Content
{{main_content}}

## Key Takeaways
- {{takeaway_1}}
- {{takeaway_2}}
- {{takeaway_3}}

## Conclusion
{{conclusion}}

---

**Tags:** {{tags}}`,
    placeholders: [
      { key: 'post_title', description: 'Title of the blog post' },
      { key: 'publication_date', description: 'When was it published' },
      { key: 'author_name', description: 'Author name' },
      { key: 'intro_paragraph', description: 'Opening paragraph' },
      { key: 'main_content', description: 'Main article content' },
      { key: 'takeaway_1', description: 'First key point' },
      { key: 'takeaway_2', description: 'Second key point' },
      { key: 'takeaway_3', description: 'Third key point' },
      { key: 'conclusion', description: 'Closing thoughts' },
      { key: 'tags', description: 'Post tags/categories' },
    ],
  },
  {
    name: 'Novel Chapter',
    category: 'novel',
    description: 'Template for writing novel chapters',
    content: `# {{novel_title}}

## Chapter {{chapter_number}}: {{chapter_title}}

**POV:** {{point_of_view}}

{{chapter_content}}

---

*Word count: {{word_count}}*`,
    placeholders: [
      { key: 'novel_title', description: 'Title of the novel' },
      { key: 'chapter_number', description: 'Chapter number' },
      { key: 'chapter_title', description: 'Chapter title' },
      { key: 'point_of_view', description: 'Character POV' },
      { key: 'chapter_content', description: 'Chapter text' },
      { key: 'word_count', description: 'Word count' },
    ],
  },
  {
    name: 'Character Profile',
    category: 'other',
    description: 'Template for character development',
    content: `# {{character_name}}

## Physical Description
{{physical_description}}

## Personality
{{personality_traits}}

## Background
{{character_background}}

## Motivations & Goals
{{motivations}}

## Flaws & Weaknesses
{{flaws}}

## Relationships
{{relationships}}

## Character Arc
{{character_arc}}`,
    placeholders: [
      { key: 'character_name', description: 'Character name' },
      { key: 'physical_description', description: 'How they look' },
      { key: 'personality_traits', description: 'Personality characteristics' },
      { key: 'character_background', description: 'Their history' },
      { key: 'motivations', description: 'What drives them' },
      { key: 'flaws', description: 'Their weaknesses' },
      { key: 'relationships', description: 'Their connections to others' },
      { key: 'character_arc', description: 'How they change' },
    ],
  },
  {
    name: 'Essay',
    category: 'essay',
    description: 'Template for essay writing',
    content: `# {{essay_title}}

## Thesis Statement
{{thesis}}

## Introduction
{{introduction}}

## Body Paragraph 1
**Topic:** {{topic_1}}
{{body_1}}

## Body Paragraph 2
**Topic:** {{topic_2}}
{{body_2}}

## Body Paragraph 3
**Topic:** {{topic_3}}
{{body_3}}

## Conclusion
{{conclusion}}

## References
{{references}}`,
    placeholders: [
      { key: 'essay_title', description: 'Essay title' },
      { key: 'thesis', description: 'Your main argument' },
      { key: 'introduction', description: 'Introductory paragraph' },
      { key: 'topic_1', description: 'First main point' },
      { key: 'body_1', description: 'First body paragraph' },
      { key: 'topic_2', description: 'Second main point' },
      { key: 'body_2', description: 'Second body paragraph' },
      { key: 'topic_3', description: 'Third main point' },
      { key: 'body_3', description: 'Third body paragraph' },
      { key: 'conclusion', description: 'Conclusion paragraph' },
      { key: 'references', description: 'References/sources' },
    ],
  },
];

export class TemplateService {
  /**
   * Get all templates (default + user-created)
   */
  getTemplates(userId?: string): Template[] {
    const db = getDatabase();

    // Get default templates
    let stmt = db.prepare('SELECT * FROM templates WHERE is_default = 1 ORDER BY name');
    let rows = stmt.all() as any[];
    const templates = rows.map((row) => this.parseTemplate(row));

    // Get user templates if userId provided
    if (userId) {
      stmt = db.prepare('SELECT * FROM templates WHERE user_id = ? ORDER BY created_at DESC');
      rows = stmt.all(userId) as any[];
      templates.push(...rows.map((row) => this.parseTemplate(row)));
    }

    return templates;
  }

  /**
   * Get template by ID
   */
  getTemplate(templateId: string): Template | null {
    const db = getDatabase();
    const stmt = db.prepare('SELECT * FROM templates WHERE id = ?');
    const row = stmt.get(templateId) as any;
    return row ? this.parseTemplate(row) : null;
  }

  /**
   * Create custom template
   */
  createTemplate(
    userId: string,
    name: string,
    category: string,
    content: string,
    placeholders: Placeholder[] = [],
    description: string = ''
  ): Template {
    const db = getDatabase();
    const id = uuidv4();
    const now = new Date().toISOString();

    const stmt = db.prepare(`
      INSERT INTO templates (id, user_id, name, category, description, content, placeholders, created_at, modified_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);

    stmt.run(
      id,
      userId,
      name,
      category,
      description,
      content,
      JSON.stringify(placeholders),
      now,
      now
    );

    return this.getTemplate(id)!;
  }

  /**
   * Seed default templates
   */
  seedDefaults(): void {
    const db = getDatabase();

    // Check if already seeded
    const check = db.prepare('SELECT COUNT(*) as count FROM templates WHERE is_default = 1');
    const result = check.get() as any;
    if (result.count > 0) return;

    const stmt = db.prepare(`
      INSERT INTO templates (id, name, category, description, content, placeholders, is_default, created_at, modified_at)
      VALUES (?, ?, ?, ?, ?, ?, 1, ?, ?)
    `);

    const now = new Date().toISOString();

    for (const template of DEFAULT_TEMPLATES) {
      stmt.run(
        uuidv4(),
        template.name,
        template.category,
        template.description,
        template.content,
        JSON.stringify(template.placeholders),
        now,
        now
      );
    }
  }

  /**
   * Fill template with values
   */
  fillTemplate(templateId: string, values: Record<string, string>): string {
    const template = this.getTemplate(templateId);
    if (!template) throw new Error('Template not found');

    let content = template.content;

    // Replace placeholders
    for (const [key, value] of Object.entries(values)) {
      const placeholder = `{{${key}}}`;
      content = content.replaceAll(placeholder, value || '');
    }

    return content;
  }

  private parseTemplate(row: any): Template {
    return {
      id: row.id,
      userId: row.user_id,
      name: row.name,
      category: row.category,
      description: row.description || '',
      content: row.content,
      placeholders: row.placeholders ? JSON.parse(row.placeholders) : [],
      isDefault: !!row.is_default,
      createdAt: row.created_at,
      modifiedAt: row.modified_at,
    };
  }
}

export const templateService = new TemplateService();
