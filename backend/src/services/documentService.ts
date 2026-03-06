import { v4 as uuidv4 } from 'uuid';
import { getDatabase } from '../db/connection.js';

export interface Document {
  id: string;
  userId: string;
  title: string;
  content: string;
  category: string;
  templateId?: string;
  wordCount: number;
  createdAt: string;
  modifiedAt: string;
  lastOpenedAt?: string;
  tags?: string[];
  metadata?: Record<string, any>;
}

export class DocumentService {
  /**
   * Create a new document
   */
  createDocument(
    userId: string,
    title: string,
    content: string = '',
    category: string = 'other',
    templateId?: string
  ): Document {
    const db = getDatabase();
    const id = uuidv4();
    const wordCount = content.split(/\s+/).filter((w) => w.length > 0).length;
    const now = new Date().toISOString();

    const stmt = db.prepare(`
      INSERT INTO documents (id, user_id, title, content, category, template_id, word_count, created_at, modified_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);

    stmt.run(id, userId, title, content, category, templateId || null, wordCount, now, now);

    return this.getDocument(id)!;
  }

  /**
   * Get a document by ID
   */
  getDocument(documentId: string): Document | null {
    const db = getDatabase();
    const stmt = db.prepare('SELECT * FROM documents WHERE id = ? AND deleted_at IS NULL');
    const row = stmt.get(documentId) as any;

    return row ? this.parseDocument(row) : null;
  }

  /**
   * Get all documents for a user
   */
  getUserDocuments(userId: string, limit: number = 50, offset: number = 0): Document[] {
    const db = getDatabase();
    const stmt = db.prepare(`
      SELECT * FROM documents
      WHERE user_id = ? AND deleted_at IS NULL
      ORDER BY modified_at DESC
      LIMIT ? OFFSET ?
    `);

    const rows = stmt.all(userId, limit, offset) as any[];
    return rows.map((row) => this.parseDocument(row));
  }

  /**
   * Search documents by title/content
   */
  searchDocuments(userId: string, query: string, limit: number = 20): Document[] {
    const db = getDatabase();
    const searchTerm = `%${query}%`;
    const stmt = db.prepare(`
      SELECT * FROM documents
      WHERE user_id = ? AND deleted_at IS NULL
        AND (title LIKE ? OR content LIKE ? OR tags LIKE ?)
      ORDER BY modified_at DESC
      LIMIT ?
    `);

    const rows = stmt.all(userId, searchTerm, searchTerm, searchTerm, limit) as any[];
    return rows.map((row) => this.parseDocument(row));
  }

  /**
   * Update a document
   */
  updateDocument(documentId: string, updates: Partial<Document>): Document | null {
    const db = getDatabase();
    const doc = this.getDocument(documentId);

    if (!doc) return null;

    const now = new Date().toISOString();
    const wordCount = updates.content
      ? updates.content.split(/\s+/).filter((w) => w.length > 0).length
      : doc.wordCount;

    const stmt = db.prepare(`
      UPDATE documents
      SET title = ?, content = ?, category = ?, word_count = ?, metadata = ?, modified_at = ?
      WHERE id = ?
    `);

    stmt.run(
      updates.title ?? doc.title,
      updates.content ?? doc.content,
      updates.category ?? doc.category,
      wordCount,
      JSON.stringify(updates.metadata ?? doc.metadata ?? {}),
      now,
      documentId
    );

    return this.getDocument(documentId);
  }

  /**
   * Delete a document (soft delete)
   */
  deleteDocument(documentId: string): boolean {
    const db = getDatabase();
    const stmt = db.prepare('UPDATE documents SET deleted_at = ? WHERE id = ?');
    const now = new Date().toISOString();
    const result = stmt.run(now, documentId);
    return result.changes > 0;
  }

  /**
   * Export document as different formats
   */
  exportDocument(documentId: string, format: 'markdown' | 'plaintext' | 'html'): string | null {
    const doc = this.getDocument(documentId);
    if (!doc) return null;

    const title = doc.title;
    const content = doc.content;

    switch (format) {
      case 'markdown':
        return `# ${title}\n\n${content}`;
      case 'plaintext':
        return `${title}\n\n${content}`;
      case 'html':
        return `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>${escapeHtml(title)}</title>
  <style>
    body { font-family: sans-serif; line-height: 1.6; max-width: 800px; margin: 0 auto; padding: 20px; }
    h1 { color: #333; }
  </style>
</head>
<body>
  <h1>${escapeHtml(title)}</h1>
  <div>${content.replace(/\n/g, '<br>')}</div>
</body>
</html>`;
      default:
        return null;
    }
  }

  /**
   * Get document statistics
   */
  getStatistics(userId: string): { totalDocuments: number; totalWords: number; averageLength: number } {
    const db = getDatabase();
    const stmt = db.prepare(`
      SELECT
        COUNT(*) as count,
        SUM(word_count) as total_words
      FROM documents
      WHERE user_id = ? AND deleted_at IS NULL
    `);

    const result = stmt.get(userId) as any;
    const count = result.count || 0;
    const totalWords = result.total_words || 0;

    return {
      totalDocuments: count,
      totalWords,
      averageLength: count > 0 ? Math.round(totalWords / count) : 0,
    };
  }

  private parseDocument(row: any): Document {
    return {
      id: row.id,
      userId: row.user_id,
      title: row.title,
      content: row.content,
      category: row.category,
      templateId: row.template_id,
      wordCount: row.word_count,
      createdAt: row.created_at,
      modifiedAt: row.modified_at,
      lastOpenedAt: row.last_opened_at,
      tags: row.tags ? row.tags.split(',') : undefined,
      metadata: row.metadata ? JSON.parse(row.metadata) : undefined,
    };
  }
}

function escapeHtml(text: string): string {
  const map: { [key: string]: string } = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#039;',
  };
  return text.replace(/[&<>"']/g, (char) => map[char]);
}

export const documentService = new DocumentService();
