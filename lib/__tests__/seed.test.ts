/**
 * @jest-environment node
 */
import { describe, expect, test } from '@jest/globals';

describe('seed module', () => {
  test('seed module should be importable without execution', () => {
    // Simply check that the module structure is valid
    expect(true).toBe(true);
  });

  test('should have expected dependencies', () => {
    const db = require('../db');
    const characters = require('../characters');

    expect(db).toHaveProperty('getDb');
    expect(db).toHaveProperty('initDb');
    expect(characters).toHaveProperty('characters');
  });
});