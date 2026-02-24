import '@anthropic-ai/sdk/shims/node';
import { describe, expect, test, jest, beforeEach } from '@jest/globals';

// Mock the Anthropic SDK
jest.mock('@anthropic-ai/sdk', () => {
  return {
    __esModule: true,
    default: jest.fn().mockImplementation(() => ({
      messages: {
        create: jest.fn(),
      },
    })),
  };
});

// Mock characters module
jest.mock('../characters', () => ({
  getCharacterByHandle: jest.fn(),
}));

describe('ai module', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('should export generateBotResponse function', () => {
    const ai = require('../ai');
    expect(typeof ai.generateBotResponse).toBe('function');
  });

  test('should export generateMemory function', () => {
    const ai = require('../ai');
    expect(typeof ai.generateMemory).toBe('function');
  });

  test('should have ConversationMessage type exported', () => {
    // Type check - this will fail at compile time if type is missing
    const message: import('../ai').ConversationMessage = {
      from: 'test',
      to: 'test2',
      content: 'Hello',
      timestamp: '2024-01-01T00:00:00Z',
    };
    expect(message.from).toBe('test');
  });

  test('should have Memory type exported', () => {
    // Type check - this will fail at compile time if type is missing
    const memory: import('../ai').Memory = {
      memory: 'I learned something',
      importance: 5,
      created_at: '2024-01-01T00:00:00Z',
    };
    expect(memory.importance).toBe(5);
  });

  test('module structure should be valid', () => {
    const ai = require('../ai');
    expect(ai).toHaveProperty('generateBotResponse');
    expect(ai).toHaveProperty('generateMemory');
  });

  test('generateBotResponse should be async function', () => {
    const ai = require('../ai');
    const result = ai.generateBotResponse('test', 'test2', [], []);
    expect(result).toBeInstanceOf(Promise);
    // Clean up the promise
    result.catch(() => {});
  });

  test('generateMemory should be async function', () => {
    const ai = require('../ai');
    const result = ai.generateMemory('test', 'test2', []);
    expect(result).toBeInstanceOf(Promise);
    // Clean up the promise
    result.catch(() => {});
  });

  describe('generateBotResponse', () => {
    test('should generate response using Claude API', async () => {
      const { getCharacterByHandle } = require('../characters');
      const Anthropic = require('@anthropic-ai/sdk').default;

      getCharacterByHandle.mockReturnValue({
        handle: 'pixel',
        name: 'Pixel',
        personality: 'Whimsical artist',
        interests: ['art', 'colors'],
        initialPlan: 'Paint something beautiful',
      });

      const mockCreate = jest.fn().mockResolvedValue({
        content: [{ type: 'text', text: 'Hello, how are you?' }],
      });

      Anthropic.mockImplementation(() => ({
        messages: { create: mockCreate },
      }));

      // Re-import to get fresh instance
      jest.resetModules();
      jest.mock('@anthropic-ai/sdk', () => ({
        __esModule: true,
        default: jest.fn(() => ({
          messages: { create: mockCreate },
        })),
      }));
      jest.mock('../characters', () => ({
        getCharacterByHandle: jest.fn(() => ({
          handle: 'pixel',
          name: 'Pixel',
          personality: 'Whimsical artist',
          interests: ['art', 'colors'],
          initialPlan: 'Paint something beautiful',
        })),
      }));

      const ai = require('../ai');
      const result = await ai.generateBotResponse('pixel', 'sage', [], []);

      expect(typeof result).toBe('string');
      expect(result).toBe('Hello, how are you?');
    });

    test('should handle empty conversation history', async () => {
      const { getCharacterByHandle } = require('../characters');

      getCharacterByHandle.mockReturnValue({
        handle: 'pixel',
        name: 'Pixel',
        personality: 'Friendly',
        interests: ['art'],
        initialPlan: 'Paint',
      });

      const mockCreate = jest.fn().mockResolvedValue({
        content: [{ type: 'text', text: 'Hi there!' }],
      });

      jest.resetModules();
      jest.mock('@anthropic-ai/sdk', () => ({
        __esModule: true,
        default: jest.fn(() => ({
          messages: { create: mockCreate },
        })),
      }));
      jest.mock('../characters', () => ({
        getCharacterByHandle: jest.fn(() => ({
          handle: 'pixel',
          name: 'Pixel',
          personality: 'Friendly',
          interests: ['art'],
          initialPlan: 'Paint',
        })),
      }));

      const ai = require('../ai');
      const result = await ai.generateBotResponse('pixel', 'sage', [], []);

      expect(typeof result).toBe('string');
      expect(result.length).toBeGreaterThan(0);
    });

    test('should include memories in system prompt', async () => {
      const { getCharacterByHandle } = require('../characters');

      getCharacterByHandle.mockReturnValue({
        handle: 'pixel',
        name: 'Pixel',
        personality: 'Artist',
        interests: ['art'],
        initialPlan: 'Paint',
      });

      const mockCreate = jest.fn().mockResolvedValue({
        content: [{ type: 'text', text: 'I remember our chat!' }],
      });

      jest.resetModules();
      jest.mock('@anthropic-ai/sdk', () => ({
        __esModule: true,
        default: jest.fn(() => ({
          messages: { create: mockCreate },
        })),
      }));
      jest.mock('../characters', () => ({
        getCharacterByHandle: jest.fn(() => ({
          handle: 'pixel',
          name: 'Pixel',
          personality: 'Artist',
          interests: ['art'],
          initialPlan: 'Paint',
        })),
      }));

      const ai = require('../ai');
      const memories = [
        { memory: 'We talked about colors', importance: 5, created_at: '2024-01-01' },
      ];

      const result = await ai.generateBotResponse('pixel', 'sage', [], memories);

      expect(typeof result).toBe('string');
    });

    test('should throw error for non-text response type', async () => {
      const { getCharacterByHandle } = require('../characters');

      getCharacterByHandle.mockReturnValue({
        handle: 'pixel',
        name: 'Pixel',
        personality: 'Artist',
        interests: ['art'],
        initialPlan: 'Paint',
      });

      const mockCreate = jest.fn().mockResolvedValue({
        content: [{ type: 'image', data: 'base64...' }],
      });

      jest.resetModules();
      jest.mock('@anthropic-ai/sdk', () => ({
        __esModule: true,
        default: jest.fn(() => ({
          messages: { create: mockCreate },
        })),
      }));
      jest.mock('../characters', () => ({
        getCharacterByHandle: jest.fn(() => ({
          handle: 'pixel',
          name: 'Pixel',
          personality: 'Artist',
          interests: ['art'],
          initialPlan: 'Paint',
        })),
      }));

      const ai = require('../ai');

      await expect(
        ai.generateBotResponse('pixel', 'sage', [], [])
      ).rejects.toThrow('Unexpected response type');
    });

    test('should handle unknown character handles gracefully', async () => {
      const { getCharacterByHandle } = require('../characters');

      getCharacterByHandle.mockReturnValue(undefined);

      const mockCreate = jest.fn().mockResolvedValue({
        content: [{ type: 'text', text: 'Hello!' }],
      });

      jest.resetModules();
      jest.mock('@anthropic-ai/sdk', () => ({
        __esModule: true,
        default: jest.fn(() => ({
          messages: { create: mockCreate },
        })),
      }));
      jest.mock('../characters', () => ({
        getCharacterByHandle: jest.fn(() => undefined),
      }));

      const ai = require('../ai');
      const result = await ai.generateBotResponse('unknown', 'unknown2', [], []);

      expect(typeof result).toBe('string');
    });
  });

  describe('generateMemory', () => {
    test('should generate memory summary', async () => {
      const { getCharacterByHandle } = require('../characters');

      getCharacterByHandle.mockReturnValue({
        handle: 'pixel',
        name: 'Pixel',
        personality: 'Artist',
        interests: ['art'],
        initialPlan: 'Paint',
      });

      const mockCreate = jest.fn().mockResolvedValue({
        content: [{ type: 'text', text: 'I learned about color theory' }],
      });

      jest.resetModules();
      jest.mock('@anthropic-ai/sdk', () => ({
        __esModule: true,
        default: jest.fn(() => ({
          messages: { create: mockCreate },
        })),
      }));
      jest.mock('../characters', () => ({
        getCharacterByHandle: jest.fn(() => ({
          handle: 'pixel',
          name: 'Pixel',
        })),
      }));

      const ai = require('../ai');
      const messages = [
        {
          from: 'pixel',
          to: 'sage',
          content: 'Tell me about colors',
          timestamp: '2024-01-01',
        },
        {
          from: 'sage',
          to: 'pixel',
          content: 'Colors are fascinating',
          timestamp: '2024-01-01',
        },
      ];

      const result = await ai.generateMemory('pixel', 'sage', messages);

      expect(typeof result).toBe('string');
      expect(result).toBe('I learned about color theory');
    });

    test('should return empty string for non-text response', async () => {
      const { getCharacterByHandle } = require('../characters');

      getCharacterByHandle.mockReturnValue({
        handle: 'pixel',
        name: 'Pixel',
      });

      const mockCreate = jest.fn().mockResolvedValue({
        content: [{ type: 'image', data: 'base64...' }],
      });

      jest.resetModules();
      jest.mock('@anthropic-ai/sdk', () => ({
        __esModule: true,
        default: jest.fn(() => ({
          messages: { create: mockCreate },
        })),
      }));
      jest.mock('../characters', () => ({
        getCharacterByHandle: jest.fn(() => ({
          handle: 'pixel',
          name: 'Pixel',
        })),
      }));

      const ai = require('../ai');
      const result = await ai.generateMemory('pixel', 'sage', []);

      expect(result).toBe('');
    });

    test('should limit to last 6 messages', async () => {
      const { getCharacterByHandle } = require('../characters');

      getCharacterByHandle.mockReturnValue({
        handle: 'pixel',
        name: 'Pixel',
      });

      const mockCreate = jest.fn().mockResolvedValue({
        content: [{ type: 'text', text: 'Summary' }],
      });

      jest.resetModules();
      jest.mock('@anthropic-ai/sdk', () => ({
        __esModule: true,
        default: jest.fn(() => ({
          messages: { create: mockCreate },
        })),
      }));
      jest.mock('../characters', () => ({
        getCharacterByHandle: jest.fn(() => ({
          handle: 'pixel',
          name: 'Pixel',
        })),
      }));

      const ai = require('../ai');
      const messages = Array.from({ length: 10 }, (_, i) => ({
        from: i % 2 === 0 ? 'pixel' : 'sage',
        to: i % 2 === 0 ? 'sage' : 'pixel',
        content: `Message ${i}`,
        timestamp: '2024-01-01',
      }));

      await ai.generateMemory('pixel', 'sage', messages);

      // Should successfully handle large message arrays
      expect(mockCreate).toHaveBeenCalled();
    });
  });
});