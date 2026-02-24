import { describe, expect, test } from '@jest/globals';
import { characters, getCharacterByHandle, Character } from '../characters';

describe('characters', () => {
  test('should export an array of characters', () => {
    expect(Array.isArray(characters)).toBe(true);
    expect(characters.length).toBeGreaterThan(0);
  });

  test('all characters should have required properties', () => {
    characters.forEach((character) => {
      expect(character).toHaveProperty('handle');
      expect(character).toHaveProperty('name');
      expect(character).toHaveProperty('description');
      expect(character).toHaveProperty('personality');
      expect(character).toHaveProperty('interests');
      expect(character).toHaveProperty('initialPlan');

      expect(typeof character.handle).toBe('string');
      expect(typeof character.name).toBe('string');
      expect(typeof character.description).toBe('string');
      expect(typeof character.personality).toBe('string');
      expect(typeof character.initialPlan).toBe('string');
      expect(Array.isArray(character.interests)).toBe(true);
    });
  });

  test('character handles should be unique', () => {
    const handles = characters.map(c => c.handle);
    const uniqueHandles = new Set(handles);
    expect(uniqueHandles.size).toBe(handles.length);
  });

  test('should include expected characters', () => {
    const handles = characters.map(c => c.handle);
    expect(handles).toContain('pixel');
    expect(handles).toContain('sage');
    expect(handles).toContain('nova');
    expect(handles).toContain('reed');
    expect(handles).toContain('zara');
  });

  test('characters should have non-empty descriptions and personalities', () => {
    characters.forEach((character) => {
      expect(character.description.length).toBeGreaterThan(0);
      expect(character.personality.length).toBeGreaterThan(0);
      expect(character.interests.length).toBeGreaterThan(0);
    });
  });
});

describe('getCharacterByHandle', () => {
  test('should return character for valid handle', () => {
    const pixel = getCharacterByHandle('pixel');
    expect(pixel).toBeDefined();
    expect(pixel?.handle).toBe('pixel');
    expect(pixel?.name).toBe('Pixel');
  });

  test('should return sage character correctly', () => {
    const sage = getCharacterByHandle('sage');
    expect(sage).toBeDefined();
    expect(sage?.handle).toBe('sage');
    expect(sage?.name).toBe('Sage');
    expect(sage?.interests).toContain('literature');
  });

  test('should return undefined for invalid handle', () => {
    const result = getCharacterByHandle('nonexistent');
    expect(result).toBeUndefined();
  });

  test('should return undefined for empty string', () => {
    const result = getCharacterByHandle('');
    expect(result).toBeUndefined();
  });

  test('should be case-sensitive', () => {
    const result = getCharacterByHandle('PIXEL');
    expect(result).toBeUndefined();
  });

  test('should return correct character properties', () => {
    const nova = getCharacterByHandle('nova');
    expect(nova).toBeDefined();
    expect(nova?.description).toContain('scientist');
    expect(nova?.interests).toContain('meteorology');
    expect(nova?.personality).toContain('Enthusiastic');
  });

  test('all character handles should be retrievable', () => {
    characters.forEach((char) => {
      const found = getCharacterByHandle(char.handle);
      expect(found).toBeDefined();
      expect(found?.handle).toBe(char.handle);
    });
  });
});