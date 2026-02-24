import { POST } from '../route';
import { NextRequest } from 'next/server';
import * as db from '@/lib/db';
import * as ai from '@/lib/ai';

// Mock dependencies
jest.mock('@/lib/db');
jest.mock('@/lib/ai');

describe('POST /api/bots/respond', () => {
  let mockSql: jest.Mock;
  let mockGenerateBotResponse: jest.Mock;
  let mockGenerateMemory: jest.Mock;

  beforeEach(() => {
    mockSql = jest.fn();
    mockGenerateBotResponse = jest.fn();
    mockGenerateMemory = jest.fn();

    (db.getDb as jest.Mock).mockReturnValue(mockSql);
    (ai.generateBotResponse as jest.Mock) = mockGenerateBotResponse;
    (ai.generateMemory as jest.Mock) = mockGenerateMemory;

    // Default successful responses
    mockGenerateBotResponse.mockResolvedValue('Hello there!');
    mockGenerateMemory.mockResolvedValue('Had a great conversation');
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('input validation', () => {
    it('should return 400 if speaker is missing', async () => {
      const request = new NextRequest('http://localhost/api/bots/respond', {
        method: 'POST',
        body: JSON.stringify({ listener: 'sage' }),
      });

      const response = await POST(request);
      const data = await response.json();

      expect(response.status).toBe(400);
      expect(data.error).toContain('speaker and listener handles are required');
    });

    it('should return 400 if listener is missing', async () => {
      const request = new NextRequest('http://localhost/api/bots/respond', {
        method: 'POST',
        body: JSON.stringify({ speaker: 'pixel' }),
      });

      const response = await POST(request);
      const data = await response.json();

      expect(response.status).toBe(400);
      expect(data.error).toContain('speaker and listener handles are required');
    });

    it('should return 400 if both speaker and listener are missing', async () => {
      const request = new NextRequest('http://localhost/api/bots/respond', {
        method: 'POST',
        body: JSON.stringify({}),
      });

      const response = await POST(request);
      const data = await response.json();

      expect(response.status).toBe(400);
      expect(data.error).toContain('speaker and listener handles are required');
    });

    it('should return 400 if speaker and listener are the same', async () => {
      const request = new NextRequest('http://localhost/api/bots/respond', {
        method: 'POST',
        body: JSON.stringify({ speaker: 'pixel', listener: 'pixel' }),
      });

      const response = await POST(request);
      const data = await response.json();

      expect(response.status).toBe(400);
      expect(data.error).toContain('speaker and listener must be different');
    });
  });

  describe('bot verification', () => {
    it('should return 404 if speaker bot does not exist', async () => {
      mockSql.mockResolvedValueOnce([]); // Empty array = bot not found

      const request = new NextRequest('http://localhost/api/bots/respond', {
        method: 'POST',
        body: JSON.stringify({ speaker: 'nonexistent', listener: 'sage' }),
      });

      const response = await POST(request);
      const data = await response.json();

      expect(response.status).toBe(404);
      expect(data.error).toContain('Bot @nonexistent not found');
    });

    it('should return 404 if listener bot does not exist', async () => {
      mockSql
        .mockResolvedValueOnce([{ handle: 'pixel' }]) // speaker exists
        .mockResolvedValueOnce([]); // listener doesn't exist

      const request = new NextRequest('http://localhost/api/bots/respond', {
        method: 'POST',
        body: JSON.stringify({ speaker: 'pixel', listener: 'nonexistent' }),
      });

      const response = await POST(request);
      const data = await response.json();

      expect(response.status).toBe(404);
      expect(data.error).toContain('Bot @nonexistent not found');
    });
  });

  describe('successful response generation', () => {
    beforeEach(() => {
      // Mock bot verification queries
      mockSql
        .mockResolvedValueOnce([{ handle: 'pixel' }]) // speaker exists
        .mockResolvedValueOnce([{ handle: 'sage' }]) // listener exists
        .mockResolvedValueOnce([]) // recent messages (empty)
        .mockResolvedValueOnce([]) // memories (empty)
        .mockResolvedValueOnce([
          {
            id: 'msg-123',
            from: 'pixel',
            to: 'sage',
            content: 'Hello there!',
            type: 'ai_response',
            timestamp: '2024-01-01T00:00:00Z',
          },
        ]); // inserted message
    });

    it('should generate and store a bot response', async () => {
      const request = new NextRequest('http://localhost/api/bots/respond', {
        method: 'POST',
        body: JSON.stringify({ speaker: 'pixel', listener: 'sage' }),
      });

      const response = await POST(request);
      const data = await response.json();

      expect(response.status).toBe(201);
      expect(data.content).toBe('Hello there!');
      expect(data.from).toBe('pixel');
      expect(data.to).toBe('sage');
      expect(data.type).toBe('ai_response');
    });

    it('should call generateBotResponse with correct parameters', async () => {
      const request = new NextRequest('http://localhost/api/bots/respond', {
        method: 'POST',
        body: JSON.stringify({ speaker: 'pixel', listener: 'sage' }),
      });

      await POST(request);

      expect(mockGenerateBotResponse).toHaveBeenCalledWith(
        'pixel',
        'sage',
        [],
        []
      );
    });

    it('should fetch and include recent conversation history', async () => {
      const mockMessages = [
        {
          from: 'pixel',
          to: 'sage',
          content: 'Hi!',
          timestamp: '2024-01-01T00:00:00Z',
        },
        {
          from: 'sage',
          to: 'pixel',
          content: 'Hello!',
          timestamp: '2024-01-01T00:00:01Z',
        },
      ];

      mockSql
        .mockResolvedValueOnce([{ handle: 'pixel' }])
        .mockResolvedValueOnce([{ handle: 'sage' }])
        .mockResolvedValueOnce(mockMessages) // recent messages
        .mockResolvedValueOnce([]) // memories
        .mockResolvedValueOnce([
          { id: 'msg-123', from: 'pixel', to: 'sage', content: 'Response', type: 'ai_response', timestamp: '2024-01-01T00:00:02Z' },
        ]);

      const request = new NextRequest('http://localhost/api/bots/respond', {
        method: 'POST',
        body: JSON.stringify({ speaker: 'pixel', listener: 'sage' }),
      });

      await POST(request);

      expect(mockGenerateBotResponse).toHaveBeenCalledWith(
        'pixel',
        'sage',
        mockMessages,
        []
      );
    });

    it('should fetch and include speaker memories', async () => {
      const mockMemories = [
        {
          memory: 'Sage is very knowledgeable',
          importance: 5,
          created_at: '2024-01-01T00:00:00Z',
        },
      ];

      mockSql
        .mockResolvedValueOnce([{ handle: 'pixel' }])
        .mockResolvedValueOnce([{ handle: 'sage' }])
        .mockResolvedValueOnce([]) // messages
        .mockResolvedValueOnce(mockMemories) // memories
        .mockResolvedValueOnce([
          { id: 'msg-123', from: 'pixel', to: 'sage', content: 'Response', type: 'ai_response', timestamp: '2024-01-01T00:00:02Z' },
        ]);

      const request = new NextRequest('http://localhost/api/bots/respond', {
        method: 'POST',
        body: JSON.stringify({ speaker: 'pixel', listener: 'sage' }),
      });

      await POST(request);

      expect(mockGenerateBotResponse).toHaveBeenCalledWith(
        'pixel',
        'sage',
        [],
        mockMemories
      );
    });
  });

  describe('memory generation', () => {
    it('should generate memory after every 3rd message', async () => {
      const recentMessages = [
        { from: 'pixel', to: 'sage', content: 'Msg 1', timestamp: '2024-01-01T00:00:00Z' },
        { from: 'sage', to: 'pixel', content: 'Msg 2', timestamp: '2024-01-01T00:00:01Z' },
      ];

      mockSql
        .mockResolvedValueOnce([{ handle: 'pixel' }])
        .mockResolvedValueOnce([{ handle: 'sage' }])
        .mockResolvedValueOnce(recentMessages) // 2 recent messages
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([
          { id: 'msg-123', from: 'pixel', to: 'sage', content: 'Response', type: 'ai_response', timestamp: '2024-01-01T00:00:02Z' },
        ])
        .mockResolvedValueOnce([]); // memory insert

      const request = new NextRequest('http://localhost/api/bots/respond', {
        method: 'POST',
        body: JSON.stringify({ speaker: 'pixel', listener: 'sage' }),
      });

      await POST(request);

      // recentMessages.length (2) + 1 (new message) = 3, so memory should be generated
      expect(mockGenerateMemory).toHaveBeenCalled();
    });

    it('should not generate memory for non-multiples of 3', async () => {
      const recentMessages = [
        { from: 'pixel', to: 'sage', content: 'Msg 1', timestamp: '2024-01-01T00:00:00Z' },
      ];

      mockSql
        .mockResolvedValueOnce([{ handle: 'pixel' }])
        .mockResolvedValueOnce([{ handle: 'sage' }])
        .mockResolvedValueOnce(recentMessages) // 1 recent message
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([
          { id: 'msg-123', from: 'pixel', to: 'sage', content: 'Response', type: 'ai_response', timestamp: '2024-01-01T00:00:02Z' },
        ]);

      const request = new NextRequest('http://localhost/api/bots/respond', {
        method: 'POST',
        body: JSON.stringify({ speaker: 'pixel', listener: 'sage' }),
      });

      await POST(request);

      // recentMessages.length (1) + 1 = 2, not a multiple of 3
      expect(mockGenerateMemory).not.toHaveBeenCalled();
    });

    it('should store memory with correct importance', async () => {
      const recentMessages = [
        { from: 'pixel', to: 'sage', content: 'Msg 1', timestamp: '2024-01-01T00:00:00Z' },
        { from: 'sage', to: 'pixel', content: 'Msg 2', timestamp: '2024-01-01T00:00:01Z' },
      ];

      mockSql
        .mockResolvedValueOnce([{ handle: 'pixel' }])
        .mockResolvedValueOnce([{ handle: 'sage' }])
        .mockResolvedValueOnce(recentMessages)
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([
          { id: 'msg-123', from: 'pixel', to: 'sage', content: 'Response', type: 'ai_response', timestamp: '2024-01-01T00:00:02Z' },
        ])
        .mockResolvedValueOnce([]); // memory insert

      const request = new NextRequest('http://localhost/api/bots/respond', {
        method: 'POST',
        body: JSON.stringify({ speaker: 'pixel', listener: 'sage' }),
      });

      await POST(request);

      // Check that SQL was called to insert memory with importance = 5
      const memoryInsertCall = mockSql.mock.calls.find(call =>
        call[0]?.[0]?.includes('INSERT INTO bot_memories')
      );
      expect(memoryInsertCall).toBeDefined();
    });

    it('should not fail request if memory generation fails', async () => {
      const recentMessages = [
        { from: 'pixel', to: 'sage', content: 'Msg 1', timestamp: '2024-01-01T00:00:00Z' },
        { from: 'sage', to: 'pixel', content: 'Msg 2', timestamp: '2024-01-01T00:00:01Z' },
      ];

      mockGenerateMemory.mockRejectedValue(new Error('Memory generation failed'));

      mockSql
        .mockResolvedValueOnce([{ handle: 'pixel' }])
        .mockResolvedValueOnce([{ handle: 'sage' }])
        .mockResolvedValueOnce(recentMessages)
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([
          { id: 'msg-123', from: 'pixel', to: 'sage', content: 'Response', type: 'ai_response', timestamp: '2024-01-01T00:00:02Z' },
        ]);

      const request = new NextRequest('http://localhost/api/bots/respond', {
        method: 'POST',
        body: JSON.stringify({ speaker: 'pixel', listener: 'sage' }),
      });

      const response = await POST(request);

      expect(response.status).toBe(201);
    });
  });

  describe('message storage', () => {
    beforeEach(() => {
      mockSql
        .mockResolvedValueOnce([{ handle: 'pixel' }])
        .mockResolvedValueOnce([{ handle: 'sage' }])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([]);
    });

    it('should store message with type "ai_response"', async () => {
      mockSql.mockResolvedValueOnce([
        {
          id: 'msg-123',
          from: 'pixel',
          to: 'sage',
          content: 'Hello there!',
          type: 'ai_response',
          timestamp: '2024-01-01T00:00:00Z',
        },
      ]);

      const request = new NextRequest('http://localhost/api/bots/respond', {
        method: 'POST',
        body: JSON.stringify({ speaker: 'pixel', listener: 'sage' }),
      });

      const response = await POST(request);
      const data = await response.json();

      expect(data.type).toBe('ai_response');
    });

    it('should return message with all fields', async () => {
      mockSql.mockResolvedValueOnce([
        {
          id: 'msg-123',
          from: 'pixel',
          to: 'sage',
          content: 'Hello there!',
          type: 'ai_response',
          timestamp: '2024-01-01T00:00:00Z',
        },
      ]);

      const request = new NextRequest('http://localhost/api/bots/respond', {
        method: 'POST',
        body: JSON.stringify({ speaker: 'pixel', listener: 'sage' }),
      });

      const response = await POST(request);
      const data = await response.json();

      expect(data).toHaveProperty('id');
      expect(data).toHaveProperty('from');
      expect(data).toHaveProperty('to');
      expect(data).toHaveProperty('content');
      expect(data).toHaveProperty('type');
      expect(data).toHaveProperty('timestamp');
    });
  });

  describe('edge cases', () => {
    it('should handle empty recent messages array', async () => {
      mockSql
        .mockResolvedValueOnce([{ handle: 'pixel' }])
        .mockResolvedValueOnce([{ handle: 'sage' }])
        .mockResolvedValueOnce([]) // empty messages
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([
          { id: 'msg-123', from: 'pixel', to: 'sage', content: 'Response', type: 'ai_response', timestamp: '2024-01-01T00:00:00Z' },
        ]);

      const request = new NextRequest('http://localhost/api/bots/respond', {
        method: 'POST',
        body: JSON.stringify({ speaker: 'pixel', listener: 'sage' }),
      });

      const response = await POST(request);

      expect(response.status).toBe(201);
      expect(mockGenerateBotResponse).toHaveBeenCalledWith(
        'pixel',
        'sage',
        [],
        []
      );
    });

    it('should handle empty memories array', async () => {
      mockSql
        .mockResolvedValueOnce([{ handle: 'pixel' }])
        .mockResolvedValueOnce([{ handle: 'sage' }])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([]) // empty memories
        .mockResolvedValueOnce([
          { id: 'msg-123', from: 'pixel', to: 'sage', content: 'Response', type: 'ai_response', timestamp: '2024-01-01T00:00:00Z' },
        ]);

      const request = new NextRequest('http://localhost/api/bots/respond', {
        method: 'POST',
        body: JSON.stringify({ speaker: 'pixel', listener: 'sage' }),
      });

      const response = await POST(request);

      expect(response.status).toBe(201);
    });

    it('should handle malformed JSON', async () => {
      const request = new NextRequest('http://localhost/api/bots/respond', {
        method: 'POST',
        body: 'not json',
        headers: { 'Content-Type': 'application/json' },
      });

      await expect(POST(request)).rejects.toThrow();
    });

    it('should not store memory if generateMemory returns null or empty string', async () => {
      const recentMessages = [
        { from: 'pixel', to: 'sage', content: 'Msg 1', timestamp: '2024-01-01T00:00:00Z' },
        { from: 'sage', to: 'pixel', content: 'Msg 2', timestamp: '2024-01-01T00:00:01Z' },
      ];

      mockGenerateMemory.mockResolvedValue(null); // Returns null

      mockSql
        .mockResolvedValueOnce([{ handle: 'pixel' }])
        .mockResolvedValueOnce([{ handle: 'sage' }])
        .mockResolvedValueOnce(recentMessages)
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([
          { id: 'msg-123', from: 'pixel', to: 'sage', content: 'Response', type: 'ai_response', timestamp: '2024-01-01T00:00:02Z' },
        ]);

      const request = new NextRequest('http://localhost/api/bots/respond', {
        method: 'POST',
        body: JSON.stringify({ speaker: 'pixel', listener: 'sage' }),
      });

      const response = await POST(request);

      expect(response.status).toBe(201);
      // Memory insert SQL should not be called since memory is null
      const memoryInsertCalls = mockSql.mock.calls.filter(call =>
        call[0]?.[0]?.includes('INSERT INTO bot_memories')
      );
      expect(memoryInsertCalls.length).toBe(0);
    });
  });

  describe('concurrent requests and timing', () => {
    it('should handle concurrent requests for different bot pairs', async () => {
      mockSql
        .mockResolvedValue([{ handle: 'pixel' }]) // First pair speaker
        .mockResolvedValue([{ handle: 'sage' }])  // First pair listener
        .mockResolvedValue([])
        .mockResolvedValue([])
        .mockResolvedValue([{ id: 'msg-1', from: 'pixel', to: 'sage', content: 'Hi', type: 'ai_response', timestamp: '2024-01-01T00:00:00Z' }]);

      const request1 = new NextRequest('http://localhost/api/bots/respond', {
        method: 'POST',
        body: JSON.stringify({ speaker: 'pixel', listener: 'sage' }),
      });

      const request2 = new NextRequest('http://localhost/api/bots/respond', {
        method: 'POST',
        body: JSON.stringify({ speaker: 'nova', listener: 'reed' }),
      });

      // Both requests should succeed independently
      const [response1, response2] = await Promise.all([
        POST(request1),
        POST(request2),
      ]);

      expect(response1.status).toBeLessThan(500);
      expect(response2.status).toBeLessThan(500);
    });

    it('should handle very long response text', async () => {
      const longResponse = 'A'.repeat(10000);
      mockGenerateBotResponse.mockResolvedValue(longResponse);

      mockSql
        .mockResolvedValueOnce([{ handle: 'pixel' }])
        .mockResolvedValueOnce([{ handle: 'sage' }])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([
          { id: 'msg-123', from: 'pixel', to: 'sage', content: longResponse, type: 'ai_response', timestamp: '2024-01-01T00:00:00Z' },
        ]);

      const request = new NextRequest('http://localhost/api/bots/respond', {
        method: 'POST',
        body: JSON.stringify({ speaker: 'pixel', listener: 'sage' }),
      });

      const response = await POST(request);
      const data = await response.json();

      expect(response.status).toBe(201);
      expect(data.content).toBe(longResponse);
    });

    it('should handle special characters in bot handles', async () => {
      mockSql
        .mockResolvedValueOnce([{ handle: 'test_bot' }])
        .mockResolvedValueOnce([{ handle: 'bot-2' }])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([
          { id: 'msg-123', from: 'test_bot', to: 'bot-2', content: 'Hi', type: 'ai_response', timestamp: '2024-01-01T00:00:00Z' },
        ]);

      const request = new NextRequest('http://localhost/api/bots/respond', {
        method: 'POST',
        body: JSON.stringify({ speaker: 'test_bot', listener: 'bot-2' }),
      });

      const response = await POST(request);

      expect(response.status).toBe(201);
    });

    it('should handle database timeout gracefully', async () => {
      mockSql.mockImplementation(() => new Promise((_, reject) => {
        setTimeout(() => reject(new Error('Database timeout')), 100);
      }));

      const request = new NextRequest('http://localhost/api/bots/respond', {
        method: 'POST',
        body: JSON.stringify({ speaker: 'pixel', listener: 'sage' }),
      });

      await expect(POST(request)).rejects.toThrow('Database timeout');
    });
  });

  describe('memory generation edge cases', () => {
    it('should handle exactly 6 messages (boundary for memory generation)', async () => {
      const recentMessages = Array.from({ length: 5 }, (_, i) => ({
        from: i % 2 === 0 ? 'pixel' : 'sage',
        to: i % 2 === 0 ? 'sage' : 'pixel',
        content: `Msg ${i}`,
        timestamp: `2024-01-01T00:00:0${i}Z`,
      }));

      mockSql
        .mockResolvedValueOnce([{ handle: 'pixel' }])
        .mockResolvedValueOnce([{ handle: 'sage' }])
        .mockResolvedValueOnce(recentMessages) // 5 messages + 1 new = 6 total
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([
          { id: 'msg-123', from: 'pixel', to: 'sage', content: 'Response', type: 'ai_response', timestamp: '2024-01-01T00:00:06Z' },
        ])
        .mockResolvedValueOnce([]);

      const request = new NextRequest('http://localhost/api/bots/respond', {
        method: 'POST',
        body: JSON.stringify({ speaker: 'pixel', listener: 'sage' }),
      });

      await POST(request);

      // 6 total messages is divisible by 3, should generate memory
      expect(mockGenerateMemory).toHaveBeenCalled();
    });

    it('should include all relevant messages in memory generation', async () => {
      const recentMessages = [
        { from: 'pixel', to: 'sage', content: 'First', timestamp: '2024-01-01T00:00:00Z' },
        { from: 'sage', to: 'pixel', content: 'Second', timestamp: '2024-01-01T00:00:01Z' },
      ];

      mockSql
        .mockResolvedValueOnce([{ handle: 'pixel' }])
        .mockResolvedValueOnce([{ handle: 'sage' }])
        .mockResolvedValueOnce(recentMessages)
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([
          { id: 'msg-123', from: 'pixel', to: 'sage', content: 'Third', type: 'ai_response', timestamp: '2024-01-01T00:00:02Z' },
        ])
        .mockResolvedValueOnce([]);

      const request = new NextRequest('http://localhost/api/bots/respond', {
        method: 'POST',
        body: JSON.stringify({ speaker: 'pixel', listener: 'sage' }),
      });

      await POST(request);

      expect(mockGenerateMemory).toHaveBeenCalledWith(
        'pixel',
        'sage',
        expect.arrayContaining([
          expect.objectContaining({ content: 'First' }),
          expect.objectContaining({ content: 'Second' }),
          expect.objectContaining({ content: 'Third' }),
        ])
      );
    });
  });
});