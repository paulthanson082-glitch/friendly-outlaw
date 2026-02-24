import { characters, getCharacterByHandle, Character } from '../characters';

describe('characters module', () => {
  describe('characters array', () => {
    it('should contain exactly 5 characters', () => {
      expect(characters).toHaveLength(5);
    });

    it('should have unique handles for all characters', () => {
      const handles = characters.map((c) => c.handle);
      const uniqueHandles = new Set(handles);
      expect(uniqueHandles.size).toBe(handles.length);
    });

    it('should have unique names for all characters', () => {
      const names = characters.map((c) => c.name);
      const uniqueNames = new Set(names);
      expect(uniqueNames.size).toBe(names.length);
    });

    it('should have all required properties for each character', () => {
      characters.forEach((char) => {
        expect(char).toHaveProperty('handle');
        expect(char).toHaveProperty('name');
        expect(char).toHaveProperty('description');
        expect(char).toHaveProperty('personality');
        expect(char).toHaveProperty('interests');
        expect(char).toHaveProperty('initialPlan');

        expect(typeof char.handle).toBe('string');
        expect(typeof char.name).toBe('string');
        expect(typeof char.description).toBe('string');
        expect(typeof char.personality).toBe('string');
        expect(Array.isArray(char.interests)).toBe(true);
        expect(typeof char.initialPlan).toBe('string');
      });
    });

    it('should have non-empty strings for all text properties', () => {
      characters.forEach((char) => {
        expect(char.handle.length).toBeGreaterThan(0);
        expect(char.name.length).toBeGreaterThan(0);
        expect(char.description.length).toBeGreaterThan(0);
        expect(char.personality.length).toBeGreaterThan(0);
        expect(char.initialPlan.length).toBeGreaterThan(0);
      });
    });

    it('should have at least one interest for each character', () => {
      characters.forEach((char) => {
        expect(char.interests.length).toBeGreaterThan(0);
        char.interests.forEach((interest) => {
          expect(typeof interest).toBe('string');
          expect(interest.length).toBeGreaterThan(0);
        });
      });
    });
  });

  describe('specific characters', () => {
    it('should include Pixel character with correct properties', () => {
      const pixel = characters.find((c) => c.handle === 'pixel');
      expect(pixel).toBeDefined();
      expect(pixel?.name).toBe('Pixel');
      expect(pixel?.description).toContain('artist');
      expect(pixel?.interests).toContain('digital art');
    });

    it('should include Sage character with correct properties', () => {
      const sage = characters.find((c) => c.handle === 'sage');
      expect(sage).toBeDefined();
      expect(sage?.name).toBe('Sage');
      expect(sage?.description).toContain('librarian');
      expect(sage?.interests).toContain('literature');
    });

    it('should include Nova character with correct properties', () => {
      const nova = characters.find((c) => c.handle === 'nova');
      expect(nova).toBeDefined();
      expect(nova?.name).toBe('Nova');
      expect(nova?.description).toContain('scientist');
      expect(nova?.interests).toContain('meteorology');
    });

    it('should include Reed character with correct properties', () => {
      const reed = characters.find((c) => c.handle === 'reed');
      expect(reed).toBeDefined();
      expect(reed?.name).toBe('Reed');
      expect(reed?.description).toContain('musician');
      expect(reed?.interests).toContain('music');
    });

    it('should include Zara character with correct properties', () => {
      const zara = characters.find((c) => c.handle === 'zara');
      expect(zara).toBeDefined();
      expect(zara?.name).toBe('Zara');
      expect(zara?.description).toContain('entrepreneur');
      expect(zara?.interests).toContain('business');
    });
  });

  describe('getCharacterByHandle', () => {
    it('should return the correct character for a valid handle', () => {
      const pixel = getCharacterByHandle('pixel');
      expect(pixel).toBeDefined();
      expect(pixel?.handle).toBe('pixel');
      expect(pixel?.name).toBe('Pixel');
    });

    it('should return the correct character for all valid handles', () => {
      const validHandles = ['pixel', 'sage', 'nova', 'reed', 'zara'];
      validHandles.forEach((handle) => {
        const char = getCharacterByHandle(handle);
        expect(char).toBeDefined();
        expect(char?.handle).toBe(handle);
      });
    });

    it('should return undefined for an invalid handle', () => {
      const result = getCharacterByHandle('nonexistent');
      expect(result).toBeUndefined();
    });

    it('should return undefined for empty string', () => {
      const result = getCharacterByHandle('');
      expect(result).toBeUndefined();
    });

    it('should be case-sensitive', () => {
      const result = getCharacterByHandle('PIXEL');
      expect(result).toBeUndefined();
    });

    it('should handle special characters gracefully', () => {
      const result = getCharacterByHandle('@pixel');
      expect(result).toBeUndefined();
    });
  });

  describe('Character type structure', () => {
    it('should match the expected Character interface', () => {
      const testCharacter: Character = {
        handle: 'test',
        name: 'Test Character',
        description: 'A test character',
        personality: 'Friendly',
        interests: ['testing'],
        initialPlan: 'Run tests',
      };

      expect(testCharacter.handle).toBe('test');
      expect(testCharacter.name).toBe('Test Character');
    });
  });

  describe('edge cases and boundary conditions', () => {
    it('should handle whitespace in handle lookup', () => {
      const result = getCharacterByHandle(' pixel ');
      expect(result).toBeUndefined();
    });

    it('should have consistent data types across all characters', () => {
      const firstChar = characters[0];
      characters.forEach((char) => {
        expect(typeof char.handle).toBe(typeof firstChar.handle);
        expect(typeof char.name).toBe(typeof firstChar.name);
        expect(typeof char.description).toBe(typeof firstChar.description);
        expect(typeof char.personality).toBe(typeof firstChar.personality);
        expect(Array.isArray(char.interests)).toBe(Array.isArray(firstChar.interests));
        expect(typeof char.initialPlan).toBe(typeof firstChar.initialPlan);
      });
    });

    it('should have unique interest combinations', () => {
      const interestSets = characters.map(c => c.interests.join('|'));
      const uniqueInterestSets = new Set(interestSets);
      expect(uniqueInterestSets.size).toBe(interestSets.length);
    });

    it('should have no empty strings in any property', () => {
      characters.forEach((char) => {
        expect(char.handle.trim()).toBe(char.handle);
        expect(char.name.trim()).toBe(char.name);
        expect(char.description.trim()).toBe(char.description);
        expect(char.personality.trim()).toBe(char.personality);
        expect(char.initialPlan.trim()).toBe(char.initialPlan);
      });
    });

    it('should have handles in lowercase', () => {
      characters.forEach((char) => {
        expect(char.handle).toBe(char.handle.toLowerCase());
      });
    });

    it('should have descriptions that are descriptive sentences', () => {
      characters.forEach((char) => {
        expect(char.description.length).toBeGreaterThan(10);
        expect(char.description).toContain(' ');
      });
    });

    it('should have personalities that are descriptive', () => {
      characters.forEach((char) => {
        expect(char.personality.length).toBeGreaterThan(10);
      });
    });

    it('should have at least 2 interests per character', () => {
      characters.forEach((char) => {
        expect(char.interests.length).toBeGreaterThanOrEqual(2);
      });
    });

    it('should not have duplicate interests within a character', () => {
      characters.forEach((char) => {
        const uniqueInterests = new Set(char.interests);
        expect(uniqueInterests.size).toBe(char.interests.length);
      });
    });

    it('should handle null as input to getCharacterByHandle', () => {
      const result = getCharacterByHandle(null as any);
      expect(result).toBeUndefined();
    });

    it('should handle undefined as input to getCharacterByHandle', () => {
      const result = getCharacterByHandle(undefined as any);
      expect(result).toBeUndefined();
    });

    it('should handle numeric input to getCharacterByHandle', () => {
      const result = getCharacterByHandle(123 as any);
      expect(result).toBeUndefined();
    });

    it('should export characters as a const array', () => {
      expect(Array.isArray(characters)).toBe(true);
      expect(characters.length).toBeGreaterThan(0);
    });
  });
});