/**
 * @jest-environment node
 */
import { describe, expect, test, jest, beforeEach } from '@jest/globals';

// Mock the neon database library
const mockSql = jest.fn();
const mockNeon = jest.fn(() => mockSql);

jest.mock('@neondatabase/serverless', () => ({
  neon: mockNeon,
}));

describe('db module', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockSql.mockClear();
    mockNeon.mockClear();
    process.env.DATABASE_URL = 'postgres://test:test@localhost:5432/test';
  });

  test('should export getDb function', () => {
    const db = require('../db');
    expect(typeof db.getDb).toBe('function');
  });

  test('should export initDb function', () => {
    const db = require('../db');
    expect(typeof db.initDb).toBe('function');
  });

  test('getDb should use DATABASE_URL environment variable when set', () => {
    // This test verifies that DATABASE_URL is used when available
    const db = require('../db');
    const sql = db.getDb();

    // Should have called neon with the DATABASE_URL
    expect(mockNeon).toHaveBeenCalled();
    expect(sql).toBeDefined();
  });

  test('module structure should be valid', () => {
    const db = require('../db');
    expect(db).toHaveProperty('getDb');
    expect(db).toHaveProperty('initDb');
  });

  test('getDb should return a SQL client', () => {
    mockSql.mockReturnValue(mockSql);

    const db = require('../db');
    const sql = db.getDb();

    expect(sql).toBeDefined();
    expect(mockNeon).toHaveBeenCalled();
  });

  test('getDb should call neon with DATABASE_URL', () => {
    const db = require('../db');
    db.getDb();

    expect(mockNeon).toHaveBeenCalledWith('postgres://test:test@localhost:5432/test');
  });

  test('initDb should be async', () => {
    const db = require('../db');
    expect(db.initDb.constructor.name).toBe('AsyncFunction');
  });

  test('initDb should create all required tables', async () => {
    mockSql.mockResolvedValue([]);

    const db = require('../db');
    await db.initDb();

    // Should have created tables: bots, messages, bot_memories, world_state
    // Plus indexes and initial world state
    expect(mockSql).toHaveBeenCalled();

    // Check for table creation calls
    const calls = mockSql.mock.calls.map((call: any) => {
      // Handle tagged template literals
      if (Array.isArray(call[0]) && call[0].raw) {
        return call[0].join('');
      }
      return String(call[0] || '');
    });

    const hasBots = calls.some((sql: string) =>
      sql.includes('CREATE TABLE IF NOT EXISTS bots')
    );
    const hasMessages = calls.some((sql: string) =>
      sql.includes('CREATE TABLE IF NOT EXISTS messages')
    );
    const hasMemories = calls.some((sql: string) =>
      sql.includes('CREATE TABLE IF NOT EXISTS bot_memories')
    );
    const hasWorldState = calls.some((sql: string) =>
      sql.includes('CREATE TABLE IF NOT EXISTS world_state')
    );

    expect(hasBots).toBe(true);
    expect(hasMessages).toBe(true);
    expect(hasMemories).toBe(true);
    expect(hasWorldState).toBe(true);
  });

  test('initDb should create indexes on messages table', async () => {
    mockSql.mockResolvedValue([]);

    const db = require('../db');
    await db.initDb();

    const calls = mockSql.mock.calls.map((call: any) => {
      if (Array.isArray(call[0]) && call[0].raw) {
        return call[0].join('');
      }
      return String(call[0] || '');
    });

    const hasFromIndex = calls.some((sql: string) =>
      sql.includes('idx_messages_from')
    );
    const hasToIndex = calls.some((sql: string) =>
      sql.includes('idx_messages_to')
    );
    const hasTimestampIndex = calls.some((sql: string) =>
      sql.includes('idx_messages_timestamp')
    );

    expect(hasFromIndex).toBe(true);
    expect(hasToIndex).toBe(true);
    expect(hasTimestampIndex).toBe(true);
  });

  test('initDb should seed default world state', async () => {
    mockSql.mockResolvedValue([]);

    const db = require('../db');
    await db.initDb();

    const calls = mockSql.mock.calls.map((call: any) => {
      if (Array.isArray(call[0]) && call[0].raw) {
        return call[0].join('');
      }
      return String(call[0] || '');
    });

    const hasWorldStateSeed = calls.some((sql: string) =>
      sql.includes('INSERT INTO world_state') &&
      (sql.includes('status') || sql.includes('tick'))
    );

    expect(hasWorldStateSeed).toBe(true);
  });

  test('initDb should handle database errors gracefully', async () => {
    mockSql.mockRejectedValue(new Error('Database error'));

    const db = require('../db');

    await expect(db.initDb()).rejects.toThrow('Database error');
  });

  test('getDb should use DATABASE_URL from environment', () => {
    const testUrl = 'postgres://custom:pass@host:5432/db';
    process.env.DATABASE_URL = testUrl;

    // Clear module cache
    jest.resetModules();
    mockNeon.mockClear();

    // Re-mock after resetModules
    jest.mock('@neondatabase/serverless', () => ({
      neon: mockNeon,
    }));

    const db = require('../db');
    db.getDb();

    expect(mockNeon).toHaveBeenCalledWith(testUrl);
  });

  test('initDb should use CASCADE on bot_memories foreign key', async () => {
    mockSql.mockResolvedValue([]);

    const db = require('../db');
    await db.initDb();

    const calls = mockSql.mock.calls.map((call: any) => {
      if (Array.isArray(call[0]) && call[0].raw) {
        return call[0].join('');
      }
      return String(call[0] || '');
    });

    const hasCascade = calls.some((sql: string) =>
      sql.includes('bot_memories') &&
      sql.includes('ON DELETE CASCADE')
    );

    expect(hasCascade).toBe(true);
  });

  test('initDb should create indexes on bot_memories table', async () => {
    mockSql.mockResolvedValue([]);

    const db = require('../db');
    await db.initDb();

    const calls = mockSql.mock.calls.map((call: any) => {
      if (Array.isArray(call[0]) && call[0].raw) {
        return call[0].join('');
      }
      return String(call[0] || '');
    });

    const hasHandleIndex = calls.some((sql: string) =>
      sql.includes('idx_bot_memories_handle')
    );
    const hasCreatedIndex = calls.some((sql: string) =>
      sql.includes('idx_bot_memories_created')
    );

    expect(hasHandleIndex).toBe(true);
    expect(hasCreatedIndex).toBe(true);
  });
});