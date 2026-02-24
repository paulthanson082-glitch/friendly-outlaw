import * as characters from '../characters';

// Mock the Anthropic SDK with a factory
const mockCreate = jest.fn();

jest.mock('@anthropic-ai/sdk', () => {
  return jest.fn().mockImplementation(() => {
    return {
      messages: {
        get create() {
          return mockCreate;
        },
      },
    };
  });
});

import { generateBotResponse, generateMemory } from '../ai';
import Anthropic from '@anthropic-ai/sdk';

const mockMessagesCreate = mockCreate;

// Mock the characters module
jest.mock('../characters', () => ({
  getCharacterByHandle: jest.fn(),
  characters: [
    {
      handle: 'pixel',
      name: 'Pixel',
      description: 'A curious artist',
      personality: 'Whimsical and introspective',
      interests: ['digital art', 'philosophy'],
      initialPlan: 'Work on a new painting',
    },
    {
      handle: 'sage',
      name: 'Sage',
      description: 'A wise librarian',
      personality: 'Calm and knowledgeable',
      interests: ['literature', 'history'],
      initialPlan: 'Organize the library',
    },
  ],
}));

describe('ai', () => {
  const mockGetCharacterByHandle = characters.getCharacterByHandle as jest.Mock;

  beforeEach(() => {
    mockMessagesCreate.mockReset();
    process.env.ANTHROPIC_API_KEY = 'test-api-key';

    // Default mock implementation for getCharacterByHandle
    mockGetCharacterByHandle.mockImplementation((handle: string) => {
      if (handle === 'pixel') {
        return {
          handle: 'pixel',
          name: 'Pixel',
          description: 'A curious artist',
          personality: 'Whimsical and introspective',
          interests: ['digital art', 'philosophy'],
          initialPlan: 'Work on a new painting',
        };
      }
      if (handle === 'sage') {
        return {
          handle: 'sage',
          name: 'Sage',
          description: 'A wise librarian',
          personality: 'Calm and knowledgeable',
          interests: ['literature', 'history'],
          initialPlan: 'Organize the library',
        };
      }
      return undefined;
    });
  });

  afterEach(() => {
    jest.clearAllMocks();
    delete process.env.ANTHROPIC_API_KEY;
  });

  describe('generateBotResponse', () => {
    it('should generate a response using Claude API', async () => {
      mockMessagesCreate.mockResolvedValue({
        content: [{ type: 'text', text: 'Hello there!' }],
      });

      const response = await generateBotResponse(
        'pixel',
        'sage',
        [],
        []
      );

      expect(response).toBe('Hello there!');
      expect(mockMessagesCreate).toHaveBeenCalledTimes(1);
    });

    it('should include conversation history in the prompt', async () => {
      mockMessagesCreate.mockResolvedValue({
        content: [{ type: 'text', text: 'Nice to see you again!' }],
      });

      const messages = [
        {
          from: 'pixel',
          to: 'sage',
          content: 'Hello!',
          timestamp: '2024-01-01T00:00:00Z',
        },
        {
          from: 'sage',
          to: 'pixel',
          content: 'Hi there!',
          timestamp: '2024-01-01T00:00:01Z',
        },
      ];

      await generateBotResponse('pixel', 'sage', messages, []);

      const callArgs = mockMessagesCreate.mock.calls[0][0];
      expect(callArgs.messages[0].content).toContain('Pixel: Hello!');
      expect(callArgs.messages[0].content).toContain('Sage: Hi there!');
    });

    it('should include memories in the system prompt', async () => {
      mockMessagesCreate.mockResolvedValue({
        content: [{ type: 'text', text: 'Based on what I remember...' }],
      });

      const memories = [
        {
          memory: 'Sage recommended a great book',
          importance: 5,
          created_at: '2024-01-01T00:00:00Z',
        },
        {
          memory: 'We discussed philosophy',
          importance: 4,
          created_at: '2024-01-01T00:01:00Z',
        },
      ];

      await generateBotResponse('pixel', 'sage', [], memories);

      const callArgs = mockMessagesCreate.mock.calls[0][0];
      expect(callArgs.system).toContain('Sage recommended a great book');
      expect(callArgs.system).toContain('We discussed philosophy');
    });

    it('should use correct model and parameters', async () => {
      mockMessagesCreate.mockResolvedValue({
        content: [{ type: 'text', text: 'Response' }],
      });

      await generateBotResponse('pixel', 'sage', [], []);

      const callArgs = mockMessagesCreate.mock.calls[0][0];
      expect(callArgs.model).toBe('claude-haiku-4-5');
      expect(callArgs.max_tokens).toBe(256);
    });

    it('should build proper system prompt with character details', async () => {
      mockMessagesCreate.mockResolvedValue({
        content: [{ type: 'text', text: 'Response' }],
      });

      await generateBotResponse('pixel', 'sage', [], []);

      const callArgs = mockMessagesCreate.mock.calls[0][0];
      expect(callArgs.system).toContain('You are Pixel');
      expect(callArgs.system).toContain('talking to Sage');
      expect(callArgs.system).toContain('Whimsical and introspective');
      expect(callArgs.system).toContain('digital art, philosophy');
      expect(callArgs.system).toContain('Work on a new painting');
    });

    it('should handle unknown characters gracefully', async () => {
      mockMessagesCreate.mockResolvedValue({
        content: [{ type: 'text', text: 'Response' }],
      });

      await generateBotResponse('unknown', 'sage', [], []);

      const callArgs = mockMessagesCreate.mock.calls[0][0];
      // When character is not found, it uses the handle directly without @
      expect(callArgs.system).toContain('You are unknown');
    });

    it('should limit conversation history to last 10 messages', async () => {
      mockMessagesCreate.mockResolvedValue({
        content: [{ type: 'text', text: 'Response' }],
      });

      const messages = Array.from({ length: 20 }, (_, i) => ({
        from: i % 2 === 0 ? 'pixel' : 'sage',
        to: i % 2 === 0 ? 'sage' : 'pixel',
        content: `Message ${i}`,
        timestamp: `2024-01-01T00:${i.toString().padStart(2, '0')}:00Z`,
      }));

      await generateBotResponse('pixel', 'sage', messages, []);

      const callArgs = mockMessagesCreate.mock.calls[0][0];
      const userContent = callArgs.messages[0].content;

      // Should only include last 10 messages (indices 10-19)
      expect(userContent).toContain('Message 10');
      expect(userContent).toContain('Message 19');
      expect(userContent).not.toContain('Message 9');
    });

    it('should handle empty conversation history', async () => {
      mockMessagesCreate.mockResolvedValue({
        content: [{ type: 'text', text: 'Hello!' }],
      });

      await generateBotResponse('pixel', 'sage', [], []);

      const callArgs = mockMessagesCreate.mock.calls[0][0];
      expect(callArgs.messages[0].content).toContain('just ran into');
      expect(callArgs.messages[0].content).toContain('Start a friendly');
    });

    it('should throw error for non-text response type', async () => {
      mockMessagesCreate.mockResolvedValue({
        content: [{ type: 'image', data: 'base64data' }],
      });

      await expect(
        generateBotResponse('pixel', 'sage', [], [])
      ).rejects.toThrow('Unexpected response type from Claude');
    });

    it('should trim whitespace from response', async () => {
      mockMessagesCreate.mockResolvedValue({
        content: [{ type: 'text', text: '  Response with spaces  \n' }],
      });

      const response = await generateBotResponse('pixel', 'sage', [], []);

      expect(response).toBe('Response with spaces');
    });

    it('should handle API errors', async () => {
      mockMessagesCreate.mockRejectedValue(new Error('API Error'));

      await expect(
        generateBotResponse('pixel', 'sage', [], [])
      ).rejects.toThrow('API Error');
    });

    it('should include rules in system prompt', async () => {
      mockMessagesCreate.mockResolvedValue({
        content: [{ type: 'text', text: 'Response' }],
      });

      await generateBotResponse('pixel', 'sage', [], []);

      const callArgs = mockMessagesCreate.mock.calls[0][0];
      expect(callArgs.system).toContain('Rules:');
      expect(callArgs.system).toContain('Speak only as Pixel');
      expect(callArgs.system).toContain('Stay fully in character');
      expect(callArgs.system).toContain('Do not mention you are an AI');
    });
  });

  describe('generateMemory', () => {
    it('should generate a memory summary', async () => {
      mockMessagesCreate.mockResolvedValue({
        content: [{ type: 'text', text: 'I learned something interesting today.' }],
      });

      const messages = [
        {
          from: 'pixel',
          to: 'sage',
          content: 'Tell me about art',
          timestamp: '2024-01-01T00:00:00Z',
        },
        {
          from: 'sage',
          to: 'pixel',
          content: 'Art is expression',
          timestamp: '2024-01-01T00:00:01Z',
        },
      ];

      const memory = await generateMemory('pixel', 'sage', messages);

      expect(memory).toBe('I learned something interesting today.');
      expect(mockMessagesCreate).toHaveBeenCalledTimes(1);
    });

    it('should include conversation transcript in prompt', async () => {
      mockMessagesCreate.mockResolvedValue({
        content: [{ type: 'text', text: 'Memory summary' }],
      });

      const messages = [
        {
          from: 'pixel',
          to: 'sage',
          content: 'Hello',
          timestamp: '2024-01-01T00:00:00Z',
        },
        {
          from: 'sage',
          to: 'pixel',
          content: 'Hi',
          timestamp: '2024-01-01T00:00:01Z',
        },
      ];

      await generateMemory('pixel', 'sage', messages);

      const callArgs = mockMessagesCreate.mock.calls[0][0];
      expect(callArgs.messages[0].content).toContain('Pixel: Hello');
      expect(callArgs.messages[0].content).toContain('Sage: Hi');
    });

    it('should limit transcript to last 6 messages', async () => {
      mockMessagesCreate.mockResolvedValue({
        content: [{ type: 'text', text: 'Memory summary' }],
      });

      const messages = Array.from({ length: 10 }, (_, i) => ({
        from: i % 2 === 0 ? 'pixel' : 'sage',
        to: i % 2 === 0 ? 'sage' : 'pixel',
        content: `Message ${i}`,
        timestamp: `2024-01-01T00:${i.toString().padStart(2, '0')}:00Z`,
      }));

      await generateMemory('pixel', 'sage', messages);

      const callArgs = mockMessagesCreate.mock.calls[0][0];
      const content = callArgs.messages[0].content;

      // Should only include last 6 messages (indices 4-9)
      expect(content).toContain('Message 4');
      expect(content).toContain('Message 9');
      expect(content).not.toContain('Message 3');
    });

    it('should use correct model and parameters for memory', async () => {
      mockMessagesCreate.mockResolvedValue({
        content: [{ type: 'text', text: 'Memory' }],
      });

      await generateMemory('pixel', 'sage', []);

      const callArgs = mockMessagesCreate.mock.calls[0][0];
      expect(callArgs.model).toBe('claude-haiku-4-5');
      expect(callArgs.max_tokens).toBe(100);
    });

    it('should include proper instructions in system prompt', async () => {
      mockMessagesCreate.mockResolvedValue({
        content: [{ type: 'text', text: 'Memory' }],
      });

      await generateMemory('pixel', 'sage', []);

      const callArgs = mockMessagesCreate.mock.calls[0][0];
      expect(callArgs.system).toContain('brief, first-person memory summaries');
      expect(callArgs.system).toContain('exactly one sentence');
      expect(callArgs.system).toContain('no quotes');
    });

    it('should mention both bot names in the prompt', async () => {
      mockMessagesCreate.mockResolvedValue({
        content: [{ type: 'text', text: 'Memory' }],
      });

      await generateMemory('pixel', 'sage', []);

      const callArgs = mockMessagesCreate.mock.calls[0][0];
      expect(callArgs.messages[0].content).toContain('Pixel');
      expect(callArgs.messages[0].content).toContain('Sage');
    });

    it('should return empty string for non-text response type', async () => {
      mockMessagesCreate.mockResolvedValue({
        content: [{ type: 'image', data: 'base64data' }],
      });

      const memory = await generateMemory('pixel', 'sage', []);

      expect(memory).toBe('');
    });

    it('should trim whitespace from memory', async () => {
      mockMessagesCreate.mockResolvedValue({
        content: [{ type: 'text', text: '  Memory with spaces  \n' }],
      });

      const memory = await generateMemory('pixel', 'sage', []);

      expect(memory).toBe('Memory with spaces');
    });

    it('should handle unknown characters in memory generation', async () => {
      mockMessagesCreate.mockResolvedValue({
        content: [{ type: 'text', text: 'Memory' }],
      });

      await generateMemory('unknown', 'sage', []);

      const callArgs = mockMessagesCreate.mock.calls[0][0];
      expect(callArgs.messages[0].content).toContain('unknown');
    });

    it('should handle API errors gracefully', async () => {
      mockMessagesCreate.mockRejectedValue(new Error('API Error'));

      await expect(
        generateMemory('pixel', 'sage', [])
      ).rejects.toThrow('API Error');
    });

    it('should handle empty message array', async () => {
      mockMessagesCreate.mockResolvedValue({
        content: [{ type: 'text', text: 'No conversation yet' }],
      });

      const memory = await generateMemory('pixel', 'sage', []);

      expect(memory).toBe('No conversation yet');
    });
  });

  describe('ConversationMessage and Memory types', () => {
    it('should accept valid ConversationMessage format', async () => {
      mockMessagesCreate.mockResolvedValue({
        content: [{ type: 'text', text: 'Response' }],
      });

      const validMessage = {
        from: 'pixel',
        to: 'sage',
        content: 'Hello',
        timestamp: '2024-01-01T00:00:00Z',
      };

      await expect(
        generateBotResponse('pixel', 'sage', [validMessage], [])
      ).resolves.toBeDefined();
    });

    it('should accept valid Memory format', async () => {
      mockMessagesCreate.mockResolvedValue({
        content: [{ type: 'text', text: 'Response' }],
      });

      const validMemory = {
        memory: 'A memorable conversation',
        importance: 5,
        created_at: '2024-01-01T00:00:00Z',
      };

      await expect(
        generateBotResponse('pixel', 'sage', [], [validMemory])
      ).resolves.toBeDefined();
    });
  });

  describe('system prompt construction edge cases', () => {
    it('should not include memory section when memories array is empty', async () => {
      mockMessagesCreate.mockResolvedValue({
        content: [{ type: 'text', text: 'Response' }],
      });

      await generateBotResponse('pixel', 'sage', [], []);

      const callArgs = mockMessagesCreate.mock.calls[0][0];
      expect(callArgs.system).not.toContain('Your recent memories:');
    });

    it('should include memory section when memories array has items', async () => {
      mockMessagesCreate.mockResolvedValue({
        content: [{ type: 'text', text: 'Response' }],
      });

      const memories = [
        {
          memory: 'Test memory',
          importance: 5,
          created_at: '2024-01-01T00:00:00Z',
        },
      ];

      await generateBotResponse('pixel', 'sage', [], memories);

      const callArgs = mockMessagesCreate.mock.calls[0][0];
      expect(callArgs.system).toContain('Your recent memories:');
      expect(callArgs.system).toContain('- Test memory');
    });
  });

  describe('API integration and error scenarios', () => {
    it('should handle rate limiting errors', async () => {
      mockMessagesCreate.mockRejectedValue(new Error('Rate limit exceeded'));

      await expect(
        generateBotResponse('pixel', 'sage', [], [])
      ).rejects.toThrow('Rate limit exceeded');
    });

    it('should handle authentication errors', async () => {
      mockMessagesCreate.mockRejectedValue(new Error('Invalid API key'));

      await expect(
        generateBotResponse('pixel', 'sage', [], [])
      ).rejects.toThrow('Invalid API key');
    });

    it('should handle network timeout', async () => {
      mockMessagesCreate.mockRejectedValue(new Error('Network timeout'));

      await expect(
        generateBotResponse('pixel', 'sage', [], [])
      ).rejects.toThrow('Network timeout');
    });

    it('should handle very long conversation history', async () => {
      mockMessagesCreate.mockResolvedValue({
        content: [{ type: 'text', text: 'Response' }],
      });

      const longHistory = Array.from({ length: 100 }, (_, i) => ({
        from: i % 2 === 0 ? 'pixel' : 'sage',
        to: i % 2 === 0 ? 'sage' : 'pixel',
        content: `Message ${i}`,
        timestamp: `2024-01-01T00:${String(i).padStart(2, '0')}:00Z`,
      }));

      await generateBotResponse('pixel', 'sage', longHistory, []);

      // Should still limit to last 10 messages
      const callArgs = mockMessagesCreate.mock.calls[0][0];
      const content = callArgs.messages[0].content;
      expect(content).toContain('Message 90');
      expect(content).toContain('Message 99');
      expect(content).not.toContain('Message 89');
    });

    it('should handle messages with special characters and emojis', async () => {
      mockMessagesCreate.mockResolvedValue({
        content: [{ type: 'text', text: 'Response with emojis 🎨 📚' }],
      });

      const messages = [
        {
          from: 'pixel',
          to: 'sage',
          content: 'Hello! 😊 How are you? 🌟',
          timestamp: '2024-01-01T00:00:00Z',
        },
      ];

      const response = await generateBotResponse('pixel', 'sage', messages, []);

      expect(response).toContain('🎨');
      expect(response).toContain('📚');
    });

    it('should handle messages with newlines and formatting', async () => {
      mockMessagesCreate.mockResolvedValue({
        content: [{ type: 'text', text: 'Response\nwith\nnewlines' }],
      });

      const messages = [
        {
          from: 'pixel',
          to: 'sage',
          content: 'Line 1\nLine 2\nLine 3',
          timestamp: '2024-01-01T00:00:00Z',
        },
      ];

      await generateBotResponse('pixel', 'sage', messages, []);

      const callArgs = mockMessagesCreate.mock.calls[0][0];
      expect(callArgs.messages[0].content).toContain('Line 1\nLine 2\nLine 3');
    });

    it('should handle memory generation with empty conversation', async () => {
      mockMessagesCreate.mockResolvedValue({
        content: [{ type: 'text', text: 'No conversation to remember' }],
      });

      const memory = await generateMemory('pixel', 'sage', []);

      expect(memory).toBe('No conversation to remember');
    });

    it('should handle very large memory objects array', async () => {
      mockMessagesCreate.mockResolvedValue({
        content: [{ type: 'text', text: 'Response' }],
      });

      const largeMemories = Array.from({ length: 100 }, (_, i) => ({
        memory: `Memory ${i}`,
        importance: i % 10,
        created_at: `2024-01-01T00:${String(i).padStart(2, '0')}:00Z`,
      }));

      await generateBotResponse('pixel', 'sage', [], largeMemories);

      const callArgs = mockMessagesCreate.mock.calls[0][0];
      // All memories should be included
      largeMemories.forEach(mem => {
        expect(callArgs.system).toContain(mem.memory);
      });
    });

    it('should handle concurrent bot response generation', async () => {
      mockMessagesCreate.mockResolvedValue({
        content: [{ type: 'text', text: 'Concurrent response' }],
      });

      const promises = [
        generateBotResponse('pixel', 'sage', [], []),
        generateBotResponse('nova', 'reed', [], []),
        generateBotResponse('zara', 'pixel', [], []),
      ];

      const results = await Promise.all(promises);

      expect(results).toHaveLength(3);
      results.forEach(result => {
        expect(result).toBe('Concurrent response');
      });
      expect(mockMessagesCreate).toHaveBeenCalledTimes(3);
    });

    it('should handle response with only whitespace', async () => {
      mockMessagesCreate.mockResolvedValue({
        content: [{ type: 'text', text: '   \n\t   ' }],
      });

      const response = await generateBotResponse('pixel', 'sage', [], []);

      expect(response).toBe('');
    });
  });
});