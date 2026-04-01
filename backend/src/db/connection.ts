import Database from 'better-sqlite3';
import { readFileSync, mkdirSync } from 'fs';
import { join, dirname } from 'path';
import logger from '../utils/logger.js';

let db: Database.Database | null = null;

export const initializeDatabase = (dbPath: string = ':memory:'): Database.Database => {
  if (db) return db;

  try {
    // Ensure the data directory exists for file-based databases
    if (dbPath !== ':memory:') {
      mkdirSync(dirname(dbPath), { recursive: true });
    }

    db = new Database(dbPath);
    db.pragma('journal_mode = WAL');

    // Read and execute schema
    const schema = readFileSync(join(process.cwd(), 'src/db/schema.sql'), 'utf-8');
    db.exec(schema);

    logger.info(`Database initialized at ${dbPath}`);
    return db;
  } catch (error) {
    logger.error('Database initialization failed:', error);
    throw error;
  }
};

export const getDatabase = (): Database.Database => {
  if (!db) {
    throw new Error('Database not initialized. Call initializeDatabase() first.');
  }
  return db;
};

export const closeDatabase = (): void => {
  if (db) {
    db.close();
    db = null;
    logger.info('Database connection closed');
  }
};

export default {
  initializeDatabase,
  getDatabase,
  closeDatabase,
};
