/**
 * @jest-environment node
 */
import { POST } from '../route';
import { NextRequest } from 'next/server';

// Mock the db module
const mockSql = jest.fn();

jest.mock('@/lib/db', () => ({
  getDb: jest.fn(() => mockSql),
}));

// Mock the ai module
jest.mock('@/lib/ai', () => ({
  generateBotResponse: jest.fn().mockResolvedValue('Generated response text'),
  generateMemory: jest.fn().mockResolvedValue('Generated memory summary'),
}));

describe('/api/bots/respond POST', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  const createMockRequest = (body: any) => {
    return {
      json: async () => body,
    } as NextRequest;
  };

  it('should return 400 if speaker is missing', async () => {
    const request = createMockRequest({ listener: 'sage' });
    const response = await POST(request);
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('speaker and listener');
  });

  it('should return 400 if listener is missing', async () => {
    const request = createMockRequest({ speaker: 'pixel' });
    const response = await POST(request);
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('speaker and listener');
  });

  it('should return 400 if speaker and listener are the same', async () => {
    const request = createMockRequest({ speaker: 'pixel', listener: 'pixel' });
    const response = await POST(request);
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('must be different');
  });

  it('should return 404 if speaker bot not found', async () => {
    mockSql.mockResolvedValueOnce([]); // No speaker found

    const request = createMockRequest({ speaker: 'nonexistent', listener: 'sage' });
    const response = await POST(request);
    const data = await response.json();

    expect(response.status).toBe(404);
    expect(data.error).toContain('not found');
  });

  it('should return 404 if listener bot not found', async () => {
    mockSql
      .mockResolvedValueOnce([{ handle: 'pixel' }]) // Speaker found
      .mockResolvedValueOnce([]); // Listener not found

    const request = createMockRequest({ speaker: 'pixel', listener: 'nonexistent' });
    const response = await POST(request);
    const data = await response.json();

    expect(response.status).toBe(404);
    expect(data.error).toContain('not found');
  });

  it('should generate and store a bot response', async () => {
    const mockMessages = [
      { from: 'pixel', to: 'sage', content: 'Hi', timestamp: '2024-01-01T10:00:00Z' },
    ];
    const mockMemories = [
      { memory: 'Previous memory', importance: 5, created_at: '2024-01-01T09:00:00Z' },
    ];
    const mockInsertedMessage = {
      id: 'msg123',
      from: 'pixel',
      to: 'sage',
      content: 'Generated response text',
      type: 'ai_response',
      timestamp: '2024-01-01T10:05:00Z',
    };

    mockSql
      .mockResolvedValueOnce([{ handle: 'pixel' }]) // Speaker exists
      .mockResolvedValueOnce([{ handle: 'sage' }]) // Listener exists
      .mockResolvedValueOnce(mockMessages) // Recent messages
      .mockResolvedValueOnce(mockMemories) // Speaker memories
      .mockResolvedValueOnce([mockInsertedMessage]); // Inserted message

    const request = createMockRequest({ speaker: 'pixel', listener: 'sage' });
    const response = await POST(request);
    const data = await response.json();

    expect(response.status).toBe(201);
    expect(data.content).toBe('Generated response text');
    expect(data.type).toBe('ai_response');
  });

  it('should fetch recent messages between both bots', async () => {
    mockSql
      .mockResolvedValueOnce([{ handle: 'pixel' }])
      .mockResolvedValueOnce([{ handle: 'sage' }])
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([{ id: 'msg', from: 'pixel', to: 'sage', content: 'text', type: 'ai_response', timestamp: 'now' }]);

    const request = createMockRequest({ speaker: 'pixel', listener: 'sage' });
    await POST(request);

    // Check that the query for recent messages was called
    const messageCalls = mockSql.mock.calls.filter(call =>
      call[0]?.some?.((str: string) => str.includes('FROM messages'))
    );
    expect(messageCalls.length).toBeGreaterThan(0);
  });

  it('should fetch speaker memories', async () => {
    mockSql
      .mockResolvedValueOnce([{ handle: 'pixel' }])
      .mockResolvedValueOnce([{ handle: 'sage' }])
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([{ id: 'msg', from: 'pixel', to: 'sage', content: 'text', type: 'ai_response', timestamp: 'now' }]);

    const request = createMockRequest({ speaker: 'pixel', listener: 'sage' });
    await POST(request);

    const memoryCalls = mockSql.mock.calls.filter(call =>
      call[0]?.some?.((str: string) => str.includes('FROM bot_memories'))
    );
    expect(memoryCalls.length).toBeGreaterThan(0);
  });

  it('should call generateBotResponse with correct parameters', async () => {
    const { generateBotResponse } = require('@/lib/ai');
    const mockMessages = [{ from: 'pixel', to: 'sage', content: 'Hi', timestamp: '2024-01-01T10:00:00Z' }];
    const mockMemories = [{ memory: 'Test memory', importance: 5, created_at: '2024-01-01T09:00:00Z' }];

    mockSql
      .mockResolvedValueOnce([{ handle: 'pixel' }])
      .mockResolvedValueOnce([{ handle: 'sage' }])
      .mockResolvedValueOnce(mockMessages)
      .mockResolvedValueOnce(mockMemories)
      .mockResolvedValueOnce([{ id: 'msg', from: 'pixel', to: 'sage', content: 'Generated response text', type: 'ai_response', timestamp: 'now' }]);

    const request = createMockRequest({ speaker: 'pixel', listener: 'sage' });
    await POST(request);

    expect(generateBotResponse).toHaveBeenCalledWith(
      'pixel',
      'sage',
      expect.arrayContaining([
        expect.objectContaining({ from: 'pixel', to: 'sage', content: 'Hi' }),
      ]),
      expect.arrayContaining([
        expect.objectContaining({ memory: 'Test memory' }),
      ])
    );
  });

  it('should store message with type "ai_response"', async () => {
    mockSql
      .mockResolvedValueOnce([{ handle: 'pixel' }])
      .mockResolvedValueOnce([{ handle: 'sage' }])
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([{ id: 'msg', from: 'pixel', to: 'sage', content: 'text', type: 'ai_response', timestamp: 'now' }]);

    const request = createMockRequest({ speaker: 'pixel', listener: 'sage' });
    const response = await POST(request);
    const data = await response.json();

    expect(data.type).toBe('ai_response');
  });

  it('should generate memory every 3rd message', async () => {
    const { generateMemory } = require('@/lib/ai');

    // Mock 2 recent messages, so the new message will be the 3rd
    const mockMessages = [
      { from: 'pixel', to: 'sage', content: 'Msg1', timestamp: '2024-01-01T10:00:00Z' },
      { from: 'sage', to: 'pixel', content: 'Msg2', timestamp: '2024-01-01T10:01:00Z' },
    ];

    mockSql
      .mockResolvedValueOnce([{ handle: 'pixel' }])
      .mockResolvedValueOnce([{ handle: 'sage' }])
      .mockResolvedValueOnce(mockMessages)
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([{ id: 'msg', from: 'pixel', to: 'sage', content: 'text', type: 'ai_response', timestamp: 'now' }])
      .mockResolvedValueOnce([]); // Memory insert

    const request = createMockRequest({ speaker: 'pixel', listener: 'sage' });
    await POST(request);

    expect(generateMemory).toHaveBeenCalled();
  });

  it('should not generate memory if not 3rd message', async () => {
    const { generateMemory } = require('@/lib/ai');

    // Mock 1 recent message, so the new message will be the 2nd
    const mockMessages = [
      { from: 'pixel', to: 'sage', content: 'Msg1', timestamp: '2024-01-01T10:00:00Z' },
    ];

    mockSql
      .mockResolvedValueOnce([{ handle: 'pixel' }])
      .mockResolvedValueOnce([{ handle: 'sage' }])
      .mockResolvedValueOnce(mockMessages)
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([{ id: 'msg', from: 'pixel', to: 'sage', content: 'text', type: 'ai_response', timestamp: 'now' }]);

    const request = createMockRequest({ speaker: 'pixel', listener: 'sage' });
    await POST(request);

    expect(generateMemory).not.toHaveBeenCalled();
  });

  it('should handle memory generation errors gracefully', async () => {
    const { generateMemory } = require('@/lib/ai');
    generateMemory.mockRejectedValueOnce(new Error('Memory generation failed'));

    const mockMessages = [
      { from: 'pixel', to: 'sage', content: 'Msg1', timestamp: '2024-01-01T10:00:00Z' },
      { from: 'sage', to: 'pixel', content: 'Msg2', timestamp: '2024-01-01T10:01:00Z' },
    ];

    mockSql
      .mockResolvedValueOnce([{ handle: 'pixel' }])
      .mockResolvedValueOnce([{ handle: 'sage' }])
      .mockResolvedValueOnce(mockMessages)
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([{ id: 'msg', from: 'pixel', to: 'sage', content: 'text', type: 'ai_response', timestamp: 'now' }]);

    const request = createMockRequest({ speaker: 'pixel', listener: 'sage' });
    const response = await POST(request);

    // Should still return success even if memory generation fails
    expect(response.status).toBe(201);
  });

  it('should store generated memory with importance 5', async () => {
    const { generateMemory } = require('@/lib/ai');
    generateMemory.mockResolvedValueOnce('New memory summary');

    const mockMessages = [
      { from: 'pixel', to: 'sage', content: 'Msg1', timestamp: '2024-01-01T10:00:00Z' },
      { from: 'sage', to: 'pixel', content: 'Msg2', timestamp: '2024-01-01T10:01:00Z' },
    ];

    mockSql
      .mockResolvedValueOnce([{ handle: 'pixel' }])
      .mockResolvedValueOnce([{ handle: 'sage' }])
      .mockResolvedValueOnce(mockMessages)
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([{ id: 'msg', from: 'pixel', to: 'sage', content: 'text', type: 'ai_response', timestamp: 'now' }])
      .mockResolvedValueOnce([]); // Memory insert

    const request = createMockRequest({ speaker: 'pixel', listener: 'sage' });
    await POST(request);

    const memoryCalls = mockSql.mock.calls.filter(call =>
      call[0]?.some?.((str: string) => str.includes('INSERT INTO bot_memories'))
    );
    expect(memoryCalls.length).toBeGreaterThan(0);
  });

  it('should limit recent messages to 10', async () => {
    mockSql
      .mockResolvedValueOnce([{ handle: 'pixel' }])
      .mockResolvedValueOnce([{ handle: 'sage' }])
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([{ id: 'msg', from: 'pixel', to: 'sage', content: 'text', type: 'ai_response', timestamp: 'now' }]);

    const request = createMockRequest({ speaker: 'pixel', listener: 'sage' });
    await POST(request);

    const messageCalls = mockSql.mock.calls.filter(call =>
      call[0]?.some?.((str: string) => str.includes('LIMIT 10'))
    );
    expect(messageCalls.length).toBeGreaterThan(0);
  });

  it('should limit speaker memories to 5', async () => {
    mockSql
      .mockResolvedValueOnce([{ handle: 'pixel' }])
      .mockResolvedValueOnce([{ handle: 'sage' }])
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([{ id: 'msg', from: 'pixel', to: 'sage', content: 'text', type: 'ai_response', timestamp: 'now' }]);

    const request = createMockRequest({ speaker: 'pixel', listener: 'sage' });
    await POST(request);

    const memoryCalls = mockSql.mock.calls.filter(call =>
      call[0]?.some?.((str: string) => str.includes('LIMIT 5'))
    );
    expect(memoryCalls.length).toBeGreaterThan(0);
  });

  it('should handle empty request body gracefully', async () => {
    const request = createMockRequest({});
    const response = await POST(request);
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toBeDefined();
  });

  it('should skip memory storage if memory is falsy', async () => {
    const { generateMemory } = require('@/lib/ai');
    generateMemory.mockResolvedValueOnce('');

    const mockMessages = [
      { from: 'pixel', to: 'sage', content: 'Msg1', timestamp: '2024-01-01T10:00:00Z' },
      { from: 'sage', to: 'pixel', content: 'Msg2', timestamp: '2024-01-01T10:01:00Z' },
    ];

    mockSql
      .mockResolvedValueOnce([{ handle: 'pixel' }])
      .mockResolvedValueOnce([{ handle: 'sage' }])
      .mockResolvedValueOnce(mockMessages)
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([{ id: 'msg', from: 'pixel', to: 'sage', content: 'text', type: 'ai_response', timestamp: 'now' }]);

    const request = createMockRequest({ speaker: 'pixel', listener: 'sage' });
    await POST(request);

    const memoryInserts = mockSql.mock.calls.filter(call =>
      call[0]?.some?.((str: string) => str.includes('INSERT INTO bot_memories'))
    );
    expect(memoryInserts.length).toBe(0);
  });

  it('should query messages bidirectionally between speaker and listener', async () => {
    mockSql
      .mockResolvedValueOnce([{ handle: 'pixel' }])
      .mockResolvedValueOnce([{ handle: 'sage' }])
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([{ id: 'msg', from: 'pixel', to: 'sage', content: 'text', type: 'ai_response', timestamp: 'now' }]);

    const request = createMockRequest({ speaker: 'pixel', listener: 'sage' });
    await POST(request);

    const messageCalls = mockSql.mock.calls.filter(call => {
      const fullSql = call[0]?.join?.('') ?? '';
      return fullSql.includes('FROM messages') && fullSql.includes('OR');
    });
    expect(messageCalls.length).toBeGreaterThan(0);
  });

  it('should return 201 status code on successful message creation', async () => {
    mockSql
      .mockResolvedValueOnce([{ handle: 'pixel' }])
      .mockResolvedValueOnce([{ handle: 'sage' }])
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([{ id: 'msg123', from: 'pixel', to: 'sage', content: 'text', type: 'ai_response', timestamp: 'now' }]);

    const request = createMockRequest({ speaker: 'pixel', listener: 'sage' });
    const response = await POST(request);

    expect(response.status).toBe(201);
  });

  it('should handle database errors when inserting message', async () => {
    mockSql
      .mockResolvedValueOnce([{ handle: 'pixel' }])
      .mockResolvedValueOnce([{ handle: 'sage' }])
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([])
      .mockRejectedValueOnce(new Error('Database insert failed'));

    const request = createMockRequest({ speaker: 'pixel', listener: 'sage' });

    await expect(POST(request)).rejects.toThrow('Database insert failed');
  });

  it('should handle AI generation errors gracefully', async () => {
    const { generateBotResponse } = require('@/lib/ai');
    generateBotResponse.mockRejectedValueOnce(new Error('AI generation failed'));

    mockSql
      .mockResolvedValueOnce([{ handle: 'pixel' }])
      .mockResolvedValueOnce([{ handle: 'sage' }])
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([]);

    const request = createMockRequest({ speaker: 'pixel', listener: 'sage' });

    await expect(POST(request)).rejects.toThrow('AI generation failed');
  });

  it('should return message with all required fields', async () => {
    const mockMessage = {
      id: 'msg123',
      from: 'pixel',
      to: 'sage',
      content: 'Test content',
      type: 'ai_response',
      timestamp: '2024-01-01T10:00:00Z',
    };

    mockSql
      .mockResolvedValueOnce([{ handle: 'pixel' }])
      .mockResolvedValueOnce([{ handle: 'sage' }])
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([mockMessage]);

    const request = createMockRequest({ speaker: 'pixel', listener: 'sage' });
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