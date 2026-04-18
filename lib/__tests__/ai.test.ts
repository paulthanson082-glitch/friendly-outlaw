import { generateBotResponse, generateMemory, ConversationMessage, Memory } from '../ai';
import { getCharacterByHandle } from '../characters';

// Store mockCreate inside the factory and expose it on the MockAnthropic class.
// This avoids the "Cannot access before initialization" TDZ issue that occurs
// when a module-level const is closed over by a jest.mock() factory that gets
// hoisted before the const is initialised (ts-jest does not apply the babel
// hoisting transform that jest.hoisted() relies on).
jest.mock('@anthropic-ai/sdk', () => {
  const mockCreate = jest.fn().mockResolvedValue({
    content: [
      {
        type: 'text',
        text: 'This is a test response from Claude.',
      },
    ],
  });
  const MockAnthropic = jest.fn().mockImplementation(() => ({
    messages: {
      create: mockCreate,
    },
  }));
  // Attach mockCreate so tests can reference it via the mock module.
  (MockAnthropic as any).mockCreate = mockCreate;
  return MockAnthropic;
});

// Convenience accessor – must be called after jest.mock is evaluated.
function getMockCreate(): jest.Mock {
  return (require('@anthropic-ai/sdk') as any).mockCreate as jest.Mock;
}

// Mock characters module
jest.mock('../characters');

describe('ai module', () => {
  const mockGetCharacterByHandle = getCharacterByHandle as jest.MockedFunction<typeof getCharacterByHandle>;

  beforeEach(() => {
    jest.clearAllMocks();
    process.env.ANTHROPIC_API_KEY = 'test-api-key';

    mockGetCharacterByHandle.mockImplementation((handle: string) => {
      if (handle === 'pixel') {
        return {
          handle: 'pixel',
          name: 'Pixel',
          description: 'A curious artist',
          personality: 'Whimsical and introspective',
          interests: ['digital art', 'philosophy'],
          initialPlan: 'Paint today',
        };
      }
      if (handle === 'sage') {
        return {
          handle: 'sage',
          name: 'Sage',
          description: 'A wise librarian',
          personality: 'Calm and measured',
          interests: ['literature', 'history'],
          initialPlan: 'Organize books',
        };
      }
      return undefined;
    });
  });

  describe('generateBotResponse', () => {
    const mockMessages: ConversationMessage[] = [
      {
        from: 'sage',
        to: 'pixel',
        content: 'Hello Pixel!',
        timestamp: '2024-01-01T10:00:00Z',
      },
      {
        from: 'pixel',
        to: 'sage',
        content: 'Hi Sage, how are you?',
        timestamp: '2024-01-01T10:01:00Z',
      },
    ];

    const mockMemories: Memory[] = [
      {
        memory: 'Had a great conversation about art',
        importance: 5,
        created_at: '2024-01-01T09:00:00Z',
      },
    ];

    it('should generate a bot response', async () => {
      const response = await generateBotResponse('pixel', 'sage', mockMessages, mockMemories);
      expect(response).toBeDefined();
      expect(typeof response).toBe('string');
      expect(response.length).toBeGreaterThan(0);
    });

    it('should call Anthropic API with correct parameters', async () => {
      const Anthropic = require('@anthropic-ai/sdk');
      const mockInstance = new Anthropic();

      await generateBotResponse('pixel', 'sage', mockMessages, mockMemories);

      expect(mockInstance.messages.create).toHaveBeenCalledWith(
        expect.objectContaining({
          model: 'claude-haiku-4-5',
          max_tokens: 256,
          messages: expect.arrayContaining([
            expect.objectContaining({
              role: 'user',
            }),
          ]),
          system: expect.any(String),
        })
      );
    });

    it('should include speaker personality in system prompt', async () => {
      const Anthropic = require('@anthropic-ai/sdk');
      const mockInstance = new Anthropic();

      await generateBotResponse('pixel', 'sage', mockMessages, mockMemories);

      const createCall = mockInstance.messages.create.mock.calls[0][0];
      expect(createCall.system).toContain('Pixel');
      expect(createCall.system).toContain('Whimsical and introspective');
    });

    it('should include memories in system prompt when provided', async () => {
      const Anthropic = require('@anthropic-ai/sdk');
      const mockInstance = new Anthropic();

      await generateBotResponse('pixel', 'sage', mockMessages, mockMemories);

      const createCall = mockInstance.messages.create.mock.calls[0][0];
      expect(createCall.system).toContain('memories');
      expect(createCall.system).toContain('Had a great conversation about art');
    });

    it('should handle empty message history', async () => {
      const response = await generateBotResponse('pixel', 'sage', [], mockMemories);
      expect(response).toBeDefined();
      expect(typeof response).toBe('string');
    });

    it('should handle empty memories', async () => {
      const response = await generateBotResponse('pixel', 'sage', mockMessages, []);
      expect(response).toBeDefined();
      expect(typeof response).toBe('string');
    });

    it('should handle unknown speaker handle', async () => {
      const response = await generateBotResponse('unknown', 'sage', mockMessages, mockMemories);
      expect(response).toBeDefined();
      expect(typeof response).toBe('string');
    });

    it('should handle unknown listener handle', async () => {
      const response = await generateBotResponse('pixel', 'unknown', mockMessages, mockMemories);
      expect(response).toBeDefined();
      expect(typeof response).toBe('string');
    });

    it('should trim whitespace from response', async () => {
      const Anthropic = require('@anthropic-ai/sdk');
      const mockInstance = new Anthropic();
      mockInstance.messages.create.mockResolvedValue({
        content: [
          {
            type: 'text',
            text: '  Response with whitespace  ',
          },
        ],
      });

      const response = await generateBotResponse('pixel', 'sage', mockMessages, mockMemories);
      expect(response).toBe('Response with whitespace');
    });

    it('should throw error for non-text response type', async () => {
      const Anthropic = require('@anthropic-ai/sdk');
      const mockInstance = new Anthropic();
      mockInstance.messages.create.mockResolvedValue({
        content: [
          {
            type: 'image',
            data: 'base64data',
          },
        ],
      });

      await expect(
        generateBotResponse('pixel', 'sage', mockMessages, mockMemories)
      ).rejects.toThrow('Unexpected response type from Claude');
    });

    it('should limit recent messages to last 10', async () => {
      const manyMessages: ConversationMessage[] = Array.from({ length: 20 }, (_, i) => ({
        from: i % 2 === 0 ? 'pixel' : 'sage',
        to: i % 2 === 0 ? 'sage' : 'pixel',
        content: `Message ${i}`,
        timestamp: new Date(Date.now() + i * 1000).toISOString(),
      }));

      const Anthropic = require('@anthropic-ai/sdk');
      const mockInstance = new Anthropic();

      await generateBotResponse('pixel', 'sage', manyMessages, mockMemories);

      const createCall = mockInstance.messages.create.mock.calls[0][0];
      const userMessage = createCall.messages[0].content;
      const messageCount = (userMessage.match(/Message \d+/g) || []).length;
      expect(messageCount).toBeLessThanOrEqual(10);
    });
  });

  describe('generateMemory', () => {
    const mockMessages: ConversationMessage[] = [
      {
        from: 'pixel',
        to: 'sage',
        content: 'I love painting landscapes',
        timestamp: '2024-01-01T10:00:00Z',
      },
      {
        from: 'sage',
        to: 'pixel',
        content: 'That sounds wonderful',
        timestamp: '2024-01-01T10:01:00Z',
      },
    ];

    it('should generate a memory summary', async () => {
      const memory = await generateMemory('pixel', 'sage', mockMessages);
      expect(memory).toBeDefined();
      expect(typeof memory).toBe('string');
    });

    it('should call Anthropic API with correct parameters', async () => {
      const Anthropic = require('@anthropic-ai/sdk');
      const mockInstance = new Anthropic();

      await generateMemory('pixel', 'sage', mockMessages);

      expect(mockInstance.messages.create).toHaveBeenCalledWith(
        expect.objectContaining({
          model: 'claude-haiku-4-5',
          max_tokens: 100,
          messages: expect.arrayContaining([
            expect.objectContaining({
              role: 'user',
            }),
          ]),
          system: expect.stringContaining('memory summaries'),
        })
      );
    });

    it('should include conversation transcript in user message', async () => {
      const Anthropic = require('@anthropic-ai/sdk');
      const mockInstance = new Anthropic();

      await generateMemory('pixel', 'sage', mockMessages);

      const createCall = mockInstance.messages.create.mock.calls[0][0];
      const userMessage = createCall.messages[0].content;
      expect(userMessage).toContain('painting landscapes');
      expect(userMessage).toContain('wonderful');
    });

    it('should mention both bot names in prompt', async () => {
      const Anthropic = require('@anthropic-ai/sdk');
      const mockInstance = new Anthropic();

      await generateMemory('pixel', 'sage', mockMessages);

      const createCall = mockInstance.messages.create.mock.calls[0][0];
      const userMessage = createCall.messages[0].content;
      expect(userMessage).toContain('Pixel');
      expect(userMessage).toContain('Sage');
    });

    it('should handle empty messages', async () => {
      const memory = await generateMemory('pixel', 'sage', []);
      expect(memory).toBeDefined();
      expect(typeof memory).toBe('string');
    });

    it('should limit messages to last 6', async () => {
      const manyMessages: ConversationMessage[] = Array.from({ length: 10 }, (_, i) => ({
        from: i % 2 === 0 ? 'pixel' : 'sage',
        to: i % 2 === 0 ? 'sage' : 'pixel',
        content: `Message ${i}`,
        timestamp: new Date(Date.now() + i * 1000).toISOString(),
      }));

      const Anthropic = require('@anthropic-ai/sdk');
      const mockInstance = new Anthropic();

      await generateMemory('pixel', 'sage', manyMessages);

      const createCall = mockInstance.messages.create.mock.calls[0][0];
      const userMessage = createCall.messages[0].content;
      const messageCount = (userMessage.match(/Message \d+/g) || []).length;
      expect(messageCount).toBeLessThanOrEqual(6);
    });

    it('should return empty string for non-text response', async () => {
      const Anthropic = require('@anthropic-ai/sdk');
      const mockInstance = new Anthropic();
      mockInstance.messages.create.mockResolvedValue({
        content: [
          {
            type: 'image',
            data: 'base64data',
          },
        ],
      });

      const memory = await generateMemory('pixel', 'sage', mockMessages);
      expect(memory).toBe('');
    });

    it('should trim whitespace from memory', async () => {
      const Anthropic = require('@anthropic-ai/sdk');
      const mockInstance = new Anthropic();
      mockInstance.messages.create.mockResolvedValue({
        content: [
          {
            type: 'text',
            text: '  Memory with spaces  ',
          },
        ],
      });

      const memory = await generateMemory('pixel', 'sage', mockMessages);
      expect(memory).toBe('Memory with spaces');
    });

    it('should handle unknown bot handles', async () => {
      const memory = await generateMemory('unknown1', 'unknown2', mockMessages);
      expect(memory).toBeDefined();
      expect(typeof memory).toBe('string');
    });
  });

  describe('edge cases and error handling', () => {
    it('should handle API errors gracefully in generateBotResponse', async () => {
      const Anthropic = require('@anthropic-ai/sdk');
      const mockInstance = new Anthropic();
      mockInstance.messages.create.mockRejectedValue(new Error('API Error'));

      await expect(
        generateBotResponse('pixel', 'sage', [], [])
      ).rejects.toThrow('API Error');
    });

    it('should handle API errors gracefully in generateMemory', async () => {
      const Anthropic = require('@anthropic-ai/sdk');
      const mockInstance = new Anthropic();
      mockInstance.messages.create.mockRejectedValue(new Error('API Error'));

      await expect(
        generateMemory('pixel', 'sage', [])
      ).rejects.toThrow('API Error');
    });

    it('should handle missing ANTHROPIC_API_KEY', () => {
      delete process.env.ANTHROPIC_API_KEY;
      // The module should still initialize but may fail on API calls
      expect(() => require('@anthropic-ai/sdk')).not.toThrow();
    });

    it('should handle rate limit errors from Anthropic API', async () => {
      const Anthropic = require('@anthropic-ai/sdk');
      const mockInstance = new Anthropic();
      mockInstance.messages.create.mockRejectedValue(new Error('Rate limit exceeded'));

      await expect(
        generateBotResponse('pixel', 'sage', [], [])
      ).rejects.toThrow('Rate limit exceeded');
    });

    it('should handle network timeout errors', async () => {
      const Anthropic = require('@anthropic-ai/sdk');
      const mockInstance = new Anthropic();
      mockInstance.messages.create.mockRejectedValue(new Error('Network timeout'));

      await expect(
        generateMemory('pixel', 'sage', [])
      ).rejects.toThrow('Network timeout');
    });

    it('should handle malformed API responses gracefully', async () => {
      const Anthropic = require('@anthropic-ai/sdk');
      const mockInstance = new Anthropic();
      mockInstance.messages.create.mockResolvedValue({
        content: null,
      });

      await expect(
        generateBotResponse('pixel', 'sage', [], [])
      ).rejects.toThrow();
    });

    it('should handle very large message histories', async () => {
      const largeHistory: ConversationMessage[] = Array.from({ length: 1000 }, (_, i) => ({
        from: i % 2 === 0 ? 'pixel' : 'sage',
        to: i % 2 === 0 ? 'sage' : 'pixel',
        content: `Message ${i}`,
        timestamp: new Date(Date.now() + i * 1000).toISOString(),
      }));

      const response = await generateBotResponse('pixel', 'sage', largeHistory, []);
      expect(response).toBeDefined();
      expect(typeof response).toBe('string');
    });

    it('should handle very large memory arrays', async () => {
      const largeMemories: Memory[] = Array.from({ length: 100 }, (_, i) => ({
        memory: `Memory ${i}`,
        importance: Math.floor(Math.random() * 10),
        created_at: new Date(Date.now() - i * 60000).toISOString(),
      }));

      const response = await generateBotResponse('pixel', 'sage', [], largeMemories);
      expect(response).toBeDefined();
      expect(typeof response).toBe('string');
    });

    it('should handle special characters in message content', async () => {
      const specialMessages: ConversationMessage[] = [
        {
          from: 'pixel',
          to: 'sage',
          content: 'Hello! <script>alert("xss")</script> & "quotes" \'apostrophes\'',
          timestamp: '2024-01-01T10:00:00Z',
        },
      ];

      const response = await generateBotResponse('pixel', 'sage', specialMessages, []);
      expect(response).toBeDefined();
      expect(typeof response).toBe('string');
    });

    it('should handle unicode and emoji in messages', async () => {
      const unicodeMessages: ConversationMessage[] = [
        {
          from: 'pixel',
          to: 'sage',
          content: '你好 🎨 مرحبا こんにちは',
          timestamp: '2024-01-01T10:00:00Z',
        },
      ];

      const response = await generateBotResponse('pixel', 'sage', unicodeMessages, []);
      expect(response).toBeDefined();
      expect(typeof response).toBe('string');
    });

    it('should preserve message order when generating response', async () => {
      const orderedMessages: ConversationMessage[] = [
        {
          from: 'pixel',
          to: 'sage',
          content: 'First',
          timestamp: '2024-01-01T10:00:00Z',
        },
        {
          from: 'sage',
          to: 'pixel',
          content: 'Second',
          timestamp: '2024-01-01T10:01:00Z',
        },
        {
          from: 'pixel',
          to: 'sage',
          content: 'Third',
          timestamp: '2024-01-01T10:02:00Z',
        },
      ];

      const Anthropic = require('@anthropic-ai/sdk');
      const mockInstance = new Anthropic();

      await generateBotResponse('pixel', 'sage', orderedMessages, []);

      const createCall = mockInstance.messages.create.mock.calls[0][0];
      const userMessage = createCall.messages[0].content;

      // Verify messages appear in order in the prompt
      const firstIndex = userMessage.indexOf('First');
      const secondIndex = userMessage.indexOf('Second');
      const thirdIndex = userMessage.indexOf('Third');

      expect(firstIndex).toBeLessThan(secondIndex);
      expect(secondIndex).toBeLessThan(thirdIndex);
    });

    it('should expose mockCreate via the mock module (factory-embedded mock pattern)', async () => {
      // Verify the mock factory embeds mockCreate and attaches it to the
      // MockAnthropic constructor so tests can inspect and override it.
      const Anthropic = require('@anthropic-ai/sdk');
      const mockInstance = new Anthropic();
      const mockCreate = getMockCreate();

      await generateBotResponse('pixel', 'sage', [], []);

      // mockInstance.messages.create IS the embedded mockCreate
      expect(mockInstance.messages.create).toBe(mockCreate);
      expect(mockCreate).toHaveBeenCalledTimes(1);
    });

    it('should allow overriding mockCreate return value per test', async () => {
      const mockCreate = getMockCreate();
      mockCreate.mockResolvedValueOnce({
        content: [{ type: 'text', text: 'Custom override response' }],
      });

      const response = await generateBotResponse('pixel', 'sage', [], []);
      expect(response).toBe('Custom override response');

      // Next call uses the default resolved value again
      const response2 = await generateBotResponse('pixel', 'sage', [], []);
      expect(response2).toBe('This is a test response from Claude.');
    });
  });
});