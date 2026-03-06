import { v4 as uuidv4 } from 'uuid';
import { getDatabase } from '../db/connection.js';

export interface KanbanTask {
  id: string;
  boardId: string;
  title: string;
  description?: string;
  column: 'backlog' | 'planning' | 'running' | 'review' | 'done';
  order: number;
  createdAt: string;
  completedAt?: string;
  metadata?: Record<string, any>;
}

export interface KanbanBoard {
  id: string;
  userId: string;
  name: string;
  description?: string;
  createdAt: string;
  metadata?: Record<string, any>;
}

export class KanbanService {
  /**
   * Create a new board
   */
  createBoard(userId: string, name: string, description?: string): KanbanBoard {
    const db = getDatabase();
    const id = uuidv4();
    const now = new Date().toISOString();

    const stmt = db.prepare(`
      INSERT INTO kanban_boards (id, user_id, name, description, created_at)
      VALUES (?, ?, ?, ?, ?)
    `);

    stmt.run(id, userId, name, description || '', now);
    return this.getBoard(id)!;
  }

  /**
   * Get all boards for a user
   */
  getUserBoards(userId: string): KanbanBoard[] {
    const db = getDatabase();
    const stmt = db.prepare('SELECT * FROM kanban_boards WHERE user_id = ? ORDER BY created_at DESC');
    const rows = stmt.all(userId) as any[];
    return rows.map((r) => this.parseBoard(r));
  }

  /**
   * Get board with all tasks
   */
  getBoard(boardId: string): KanbanBoard | null {
    const db = getDatabase();
    const stmt = db.prepare('SELECT * FROM kanban_boards WHERE id = ?');
    const row = stmt.get(boardId) as any;
    return row ? this.parseBoard(row) : null;
  }

  /**
   * Create a task
   */
  createTask(
    boardId: string,
    title: string,
    description?: string,
    column: string = 'backlog'
  ): KanbanTask {
    const db = getDatabase();
    const id = uuidv4();
    const now = new Date().toISOString();

    // Get max order for column
    const orderStmt = db.prepare(
      'SELECT MAX(task_order) as max_order FROM kanban_tasks WHERE board_id = ? AND column = ?'
    );
    const result = orderStmt.get(boardId, column) as any;
    const order = (result.max_order || 0) + 1;

    const stmt = db.prepare(`
      INSERT INTO kanban_tasks (id, board_id, title, description, column, task_order, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `);

    stmt.run(id, boardId, title, description || '', column, order, now);
    return this.getTask(id)!;
  }

  /**
   * Get a task
   */
  getTask(taskId: string): KanbanTask | null {
    const db = getDatabase();
    const stmt = db.prepare('SELECT * FROM kanban_tasks WHERE id = ?');
    const row = stmt.get(taskId) as any;
    return row ? this.parseTask(row) : null;
  }

  /**
   * Get all tasks for a board
   */
  getTasks(boardId: string): KanbanTask[] {
    const db = getDatabase();
    const stmt = db.prepare(
      'SELECT * FROM kanban_tasks WHERE board_id = ? ORDER BY column, task_order'
    );
    const rows = stmt.all(boardId) as any[];
    return rows.map((r) => this.parseTask(r));
  }

  /**
   * Get tasks by column
   */
  getTasksByColumn(boardId: string, column: string): KanbanTask[] {
    const db = getDatabase();
    const stmt = db.prepare(
      'SELECT * FROM kanban_tasks WHERE board_id = ? AND column = ? ORDER BY task_order'
    );
    const rows = stmt.all(boardId, column) as any[];
    return rows.map((r) => this.parseTask(r));
  }

  /**
   * Move task to column
   */
  moveTask(taskId: string, newColumn: string): KanbanTask | null {
    const db = getDatabase();
    const task = this.getTask(taskId);
    if (!task) return null;

    // Get max order for new column
    const orderStmt = db.prepare(
      'SELECT MAX(task_order) as max_order FROM kanban_tasks WHERE board_id = ? AND column = ?'
    );
    const result = orderStmt.get(task.boardId, newColumn) as any;
    const newOrder = (result.max_order || 0) + 1;

    const updateStmt = db.prepare(
      'UPDATE kanban_tasks SET column = ?, task_order = ? WHERE id = ?'
    );
    updateStmt.run(newColumn, newOrder, taskId);

    return this.getTask(taskId);
  }

  /**
   * Update task
   */
  updateTask(taskId: string, updates: Partial<KanbanTask>): KanbanTask | null {
    const db = getDatabase();
    const task = this.getTask(taskId);
    if (!task) return null;

    const stmt = db.prepare(
      'UPDATE kanban_tasks SET title = ?, description = ? WHERE id = ?'
    );

    stmt.run(updates.title ?? task.title, updates.description ?? task.description, taskId);

    return this.getTask(taskId);
  }

  /**
   * Delete a task
   */
  deleteTask(taskId: string): boolean {
    const db = getDatabase();
    const stmt = db.prepare('DELETE FROM kanban_tasks WHERE id = ?');
    const result = stmt.run(taskId);
    return result.changes > 0;
  }

  /**
   * Delete a board (cascade)
   */
  deleteBoard(boardId: string): boolean {
    const db = getDatabase();
    const stmt = db.prepare('DELETE FROM kanban_boards WHERE id = ?');
    const result = stmt.run(boardId);
    return result.changes > 0;
  }

  private parseBoard(row: any): KanbanBoard {
    return {
      id: row.id,
      userId: row.user_id,
      name: row.name,
      description: row.description,
      createdAt: row.created_at,
      metadata: row.metadata ? JSON.parse(row.metadata) : undefined,
    };
  }

  private parseTask(row: any): KanbanTask {
    return {
      id: row.id,
      boardId: row.board_id,
      title: row.title,
      description: row.description,
      column: row.column,
      order: row.task_order,
      createdAt: row.created_at,
      completedAt: row.completed_at,
      metadata: row.metadata ? JSON.parse(row.metadata) : undefined,
    };
  }
}

function getDatabase() {
  const { getDatabase: getDb } = require('../db/connection.js');
  return getDb();
}

export const kanbanService = new KanbanService();
