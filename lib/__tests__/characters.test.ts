import { characters, getCharacterByHandle, type Character } from '../characters';

describe('characters', () => {
  describe('characters array', () => {
    it('should contain all 5 characters', () => {
      expect(characters).toHaveLength(5);
    });

    it('should have unique handles', () => {
      const handles = characters.map(c => c.handle);
      const uniqueHandles = new Set(handles);
      expect(uniqueHandles.size).toBe(handles.length);
    });

    it('should have unique names', () => {
      const names = characters.map(c => c.name);
      const uniqueNames = new Set(names);
      expect(uniqueNames.size).toBe(names.length);
    });

    it('should include expected characters', () => {
      const handles = characters.map(c => c.handle);
      expect(handles).toContain('pixel');
      expect(handles).toContain('sage');
      expect(handles).toContain('nova');
      expect(handles).toContain('reed');
      expect(handles).toContain('zara');
    });

    it('should have all required fields for each character', () => {
      characters.forEach(character => {
        expect(character.handle).toBeDefined();
        expect(character.name).toBeDefined();
        expect(character.description).toBeDefined();
        expect(character.personality).toBeDefined();
        expect(character.interests).toBeDefined();
        expect(character.initialPlan).toBeDefined();

        expect(typeof character.handle).toBe('string');
        expect(typeof character.name).toBe('string');
        expect(typeof character.description).toBe('string');
        expect(typeof character.personality).toBe('string');
        expect(Array.isArray(character.interests)).toBe(true);
        expect(typeof character.initialPlan).toBe('string');
      });
    });

    it('should have non-empty strings for text fields', () => {
      characters.forEach(character => {
        expect(character.handle.length).toBeGreaterThan(0);
        expect(character.name.length).toBeGreaterThan(0);
        expect(character.description.length).toBeGreaterThan(0);
        expect(character.personality.length).toBeGreaterThan(0);
        expect(character.initialPlan.length).toBeGreaterThan(0);
      });
    });

    it('should have at least one interest for each character', () => {
      characters.forEach(character => {
        expect(character.interests.length).toBeGreaterThan(0);
      });
    });
  });

  describe('getCharacterByHandle', () => {
    it('should return the correct character for valid handles', () => {
      const pixel = getCharacterByHandle('pixel');
      expect(pixel).toBeDefined();
      expect(pixel?.handle).toBe('pixel');
      expect(pixel?.name).toBe('Pixel');

      const sage = getCharacterByHandle('sage');
      expect(sage).toBeDefined();
      expect(sage?.handle).toBe('sage');
      expect(sage?.name).toBe('Sage');

      const nova = getCharacterByHandle('nova');
      expect(nova).toBeDefined();
      expect(nova?.handle).toBe('nova');
      expect(nova?.name).toBe('Nova');

      const reed = getCharacterByHandle('reed');
      expect(reed).toBeDefined();
      expect(reed?.handle).toBe('reed');
      expect(reed?.name).toBe('Reed');

      const zara = getCharacterByHandle('zara');
      expect(zara).toBeDefined();
      expect(zara?.handle).toBe('zara');
      expect(zara?.name).toBe('Zara');
    });

    it('should return undefined for non-existent handles', () => {
      expect(getCharacterByHandle('invalid')).toBeUndefined();
      expect(getCharacterByHandle('nonexistent')).toBeUndefined();
      expect(getCharacterByHandle('')).toBeUndefined();
    });

    it('should be case-sensitive', () => {
      expect(getCharacterByHandle('Pixel')).toBeUndefined();
      expect(getCharacterByHandle('PIXEL')).toBeUndefined();
      expect(getCharacterByHandle('pixel')).toBeDefined();
    });

    it('should return a character with all expected properties', () => {
      const character = getCharacterByHandle('pixel');
      expect(character).toMatchObject({
        handle: expect.any(String),
        name: expect.any(String),
        description: expect.any(String),
        personality: expect.any(String),
        interests: expect.any(Array),
        initialPlan: expect.any(String),
      });
    });

    it('should handle whitespace in handles', () => {
      expect(getCharacterByHandle(' pixel')).toBeUndefined();
      expect(getCharacterByHandle('pixel ')).toBeUndefined();
      expect(getCharacterByHandle(' pixel ')).toBeUndefined();
    });

    it('should return the same object reference on multiple calls', () => {
      const first = getCharacterByHandle('pixel');
      const second = getCharacterByHandle('pixel');
      expect(first).toBe(second);
    });
  });

  describe('Character type validation', () => {
    it('should match the Character interface structure', () => {
      const testCharacter: Character = {
        handle: 'test',
        name: 'Test Character',
        description: 'A test description',
        personality: 'Friendly and helpful',
        interests: ['testing', 'validation'],
        initialPlan: 'Run tests all day',
      };

      expect(testCharacter.handle).toBe('test');
      expect(testCharacter.interests).toContain('testing');
    });
  });

  describe('Specific character properties', () => {
    it('should have correct properties for Pixel', () => {
      const pixel = getCharacterByHandle('pixel');
      expect(pixel?.name).toBe('Pixel');
      expect(pixel?.interests).toContain('digital art');
      expect(pixel?.description).toContain('artist');
    });

    it('should have correct properties for Sage', () => {
      const sage = getCharacterByHandle('sage');
      expect(sage?.name).toBe('Sage');
      expect(sage?.interests).toContain('literature');
      expect(sage?.description).toContain('librarian');
    });

    it('should have correct properties for Nova', () => {
      const nova = getCharacterByHandle('nova');
      expect(nova?.name).toBe('Nova');
      expect(nova?.interests).toContain('meteorology');
      expect(nova?.description).toContain('scientist');
    });

    it('should have correct properties for Reed', () => {
      const reed = getCharacterByHandle('reed');
      expect(reed?.name).toBe('Reed');
      expect(reed?.interests).toContain('music');
      expect(reed?.description).toContain('musician');
    });

    it('should have correct properties for Zara', () => {
      const zara = getCharacterByHandle('zara');
      expect(zara?.name).toBe('Zara');
      expect(zara?.interests).toContain('business');
      expect(zara?.description).toContain('entrepreneur');
    });
  });

  describe('Edge cases and boundary conditions', () => {
    it('should handle null and undefined inputs gracefully', () => {
      expect(getCharacterByHandle(null as any)).toBeUndefined();
      expect(getCharacterByHandle(undefined as any)).toBeUndefined();
    });

    it('should ensure all characters have multiple interests', () => {
      characters.forEach(character => {
        expect(character.interests.length).toBeGreaterThanOrEqual(2);
      });
    });

    it('should verify personality descriptions are substantial', () => {
      characters.forEach(character => {
        expect(character.personality.length).toBeGreaterThan(20);
      });
    });
  });

  describe('Performance and scalability', () => {
    it('should handle rapid sequential lookups efficiently', () => {
      const startTime = Date.now();

      for (let i = 0; i < 1000; i++) {
        getCharacterByHandle('pixel');
        getCharacterByHandle('sage');
        getCharacterByHandle('nova');
      }

      const endTime = Date.now();
      const elapsed = endTime - startTime;

      // 3000 lookups should complete in under 100ms
      expect(elapsed).toBeLessThan(100);
    });

    it('should handle all valid handles in a single test', () => {
      const allHandles = ['pixel', 'sage', 'nova', 'reed', 'zara'];
      const results = allHandles.map(handle => getCharacterByHandle(handle));

      results.forEach((result, index) => {
        expect(result).toBeDefined();
        expect(result?.handle).toBe(allHandles[index]);
      });
    });

    it('should verify character data consistency', () => {
      characters.forEach(char => {
        const retrieved = getCharacterByHandle(char.handle);
        expect(retrieved).toEqual(char);
      });
    });
  });

  describe('Data validation edge cases', () => {
    it('should not have characters with duplicate names', () => {
      const names = characters.map(c => c.name.toLowerCase());
      const uniqueNames = new Set(names);
      expect(uniqueNames.size).toBe(names.length);
    });

    it('should ensure all interests are lowercase', () => {
      characters.forEach(char => {
        char.interests.forEach(interest => {
          expect(interest).toBe(interest.toLowerCase());
        });
      });
    });

    it('should ensure no empty strings in interests', () => {
      characters.forEach(char => {
        char.interests.forEach(interest => {
          expect(interest.trim().length).toBeGreaterThan(0);
        });
      });
    });

    it('should verify descriptions end with proper punctuation', () => {
      characters.forEach(char => {
        const lastChar = char.description.trim().slice(-1);
        expect(['.', '!', '?']).toContain(lastChar);
      });
    });

    it('should ensure personality descriptions are descriptive', () => {
      characters.forEach(char => {
        // Personality should have at least 2 words
        const words = char.personality.split(/\s+/).filter(w => w.length > 0);
        expect(words.length).toBeGreaterThanOrEqual(2);
      });
    });

    it('should verify initial plans are actionable', () => {
      characters.forEach(char => {
        // Initial plan should be at least 3 words
        const words = char.initialPlan.split(/\s+/).filter(w => w.length > 0);
        expect(words.length).toBeGreaterThanOrEqual(3);
      });
    });

    it('should ensure handles are URL-safe', () => {
      characters.forEach(char => {
        // Should only contain alphanumeric and underscore/hyphen
        expect(char.handle).toMatch(/^[a-z0-9_-]+$/);
      });
    });

    it('should handle getCharacterByHandle with extreme inputs', () => {
      const extremeInputs = [
        '',
        ' ',
        '\n',
        '\t',
        'a'.repeat(1000),
        '!!!',
        '123',
        'pixel\x00sage',
      ];

      extremeInputs.forEach(input => {
        const result = getCharacterByHandle(input);
        // Should either return undefined or a valid character
        expect(result === undefined || (result && result.handle)).toBeTruthy();
      });
    });
  });

  describe('Character relationships and design', () => {
    it('should have diverse interest domains', () => {
      const allInterests = characters.flatMap(c => c.interests);
      const uniqueInterests = new Set(allInterests);

      // Should have at least 15 unique interests across all characters
      expect(uniqueInterests.size).toBeGreaterThanOrEqual(15);
    });

    it('should ensure each character has unique personality traits', () => {
      const personalities = characters.map(c => c.personality.toLowerCase());

      // Check that personalities are not identical
      const uniquePersonalities = new Set(personalities);
      expect(uniquePersonalities.size).toBe(characters.length);
    });

    it('should verify characters have different roles/archetypes', () => {
      const roles = characters.map(c => c.description.toLowerCase());
      const hasArtist = roles.some(r => r.includes('artist'));
      const hasLibrarian = roles.some(r => r.includes('librarian'));
      const hasScientist = roles.some(r => r.includes('scientist'));
      const hasMusician = roles.some(r => r.includes('musician'));
      const hasEntrepreneur = roles.some(r => r.includes('entrepreneur'));

      expect(hasArtist).toBe(true);
      expect(hasLibrarian).toBe(true);
      expect(hasScientist).toBe(true);
      expect(hasMusician).toBe(true);
      expect(hasEntrepreneur).toBe(true);
    });
  });
});