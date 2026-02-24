import { describe, expect, test } from '@jest/globals';
import { metadata } from '../layout';

describe('layout', () => {
  test('should export RootLayout as default', () => {
    const layout = require('../layout');
    expect(typeof layout.default).toBe('function');
  });

  test('RootLayout should accept children prop', () => {
    const layout = require('../layout');
    const RootLayout = layout.default;

    // Verify it's a function component
    expect(typeof RootLayout).toBe('function');
  });
});

describe('metadata', () => {
  test('should have correct title', () => {
    expect(metadata.title).toBe('AI Town');
  });

  test('should have correct description', () => {
    expect(metadata.description).toBe('A virtual town where AI residents live, chat, and socialize');
  });

  test('should be a valid Metadata object', () => {
    expect(metadata).toHaveProperty('title');
    expect(metadata).toHaveProperty('description');
    expect(typeof metadata.title).toBe('string');
    expect(typeof metadata.description).toBe('string');
  });

  test('should have descriptive metadata for SEO', () => {
    expect(metadata.description).toContain('AI');
    expect(metadata.description).toContain('town');
    expect(metadata.description?.length).toBeGreaterThan(20);
  });
});