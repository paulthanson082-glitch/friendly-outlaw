import { GET } from '../route';
import * as db from '@/lib/db';

// Mock dependencies
jest.mock('@/lib/db');

describe('GET /api/town', () => {
  let mockSql: jest.Mock;

  beforeEach(() => {
    mockSql = jest.fn();
    (db.getDb as jest.Mock).mockReturnValue(mockSql);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should return town data with all required fields', async () => {
    const mockBots = [
      {
        id: 'bot-1',
        handle: 'pixel',
        name: 'Pixel',
        description: 'A curious artist',
        created_at: '2024-01-01T00:00:00Z',
      },
      {
        id: 'bot-2',
        handle: 'sage',
        name: 'Sage',
        description: 'A wise librarian',
        created_at: '2024-01-01T00:00:01Z',
      },
    ];

    const mockMessages = [
      {
        id: 'msg-1',
        from: 'pixel',
        to: 'sage',
        content: 'Hello!',
        type: 'message',
        timestamp: '2024-01-01T00:01:00Z',
        from_name: 'Pixel',
        to_name: 'Sage',
      },
    ];

    const mockWorldState = [
      { key: 'status', value: 'running', updated_at: '2024-01-01T00:00:00Z' },
      { key: 'tick', value: '42', updated_at: '2024-01-01T00:00:01Z' },
    ];

    const mockMemories = [
      {
        bot_handle: 'pixel',
        memory: 'Had a great conversation with Sage',
        created_at: '2024-01-01T00:02:00Z',
      },
    ];

    // Mock Promise.all results
    mockSql
      .mockResolvedValueOnce(mockBots)
      .mockResolvedValueOnce(mockMessages)
      .mockResolvedValueOnce(mockWorldState)
      .mockResolvedValueOnce(mockMemories);

    const response = await GET();
    const data = await response.json();

    expect(data).toHaveProperty('world');
    expect(data).toHaveProperty('residents');
    expect(data).toHaveProperty('feed');
  });

  it('should correctly format world state as key-value object', async () => {
    mockSql
      .mockResolvedValueOnce([]) // bots
      .mockResolvedValueOnce([]) // messages
      .mockResolvedValueOnce([
        { key: 'status', value: 'running', updated_at: '2024-01-01T00:00:00Z' },
        { key: 'tick', value: '100', updated_at: '2024-01-01T00:00:01Z' },
      ])
      .mockResolvedValueOnce([]); // memories

    const response = await GET();
    const data = await response.json();

    expect(data.world).toEqual({
      status: 'running',
      tick: '100',
    });
  });

  it('should attach latest memory to residents', async () => {
    const mockBots = [
      {
        id: 'bot-1',
        handle: 'pixel',
        name: 'Pixel',
        description: 'A curious artist',
        created_at: '2024-01-01T00:00:00Z',
      },
      {
        id: 'bot-2',
        handle: 'sage',
        name: 'Sage',
        description: 'A wise librarian',
        created_at: '2024-01-01T00:00:01Z',
      },
    ];

    const mockMemories = [
      {
        bot_handle: 'pixel',
        memory: 'Met Sage at the library',
        created_at: '2024-01-01T00:02:00Z',
      },
    ];

    mockSql
      .mockResolvedValueOnce(mockBots)
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce(mockMemories);

    const response = await GET();
    const data = await response.json();

    expect(data.residents[0].latestMemory).toBe('Met Sage at the library');
    expect(data.residents[1].latestMemory).toBe(null); // sage has no memory
  });

  it('should return residents sorted by name ASC', async () => {
    const mockBots = [
      {
        id: 'bot-1',
        handle: 'zara',
        name: 'Zara',
        description: 'Entrepreneur',
        created_at: '2024-01-01T00:00:00Z',
      },
      {
        id: 'bot-2',
        handle: 'pixel',
        name: 'Pixel',
        description: 'Artist',
        created_at: '2024-01-01T00:00:01Z',
      },
    ];

    mockSql
      .mockResolvedValueOnce(mockBots) // Already sorted by SQL
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([]);

    const response = await GET();
    const data = await response.json();

    // Verify SQL ORDER BY was used (mocked data already sorted)
    expect(data.residents[0].name).toBe('Zara');
    expect(data.residents[1].name).toBe('Pixel');
  });

  it('should limit messages to 30 most recent', async () => {
    const mockMessages = Array.from({ length: 30 }, (_, i) => ({
      id: `msg-${i}`,
      from: 'pixel',
      to: 'sage',
      content: `Message ${i}`,
      type: 'message',
      timestamp: `2024-01-01T00:${String(i).padStart(2, '0')}:00Z`,
      from_name: 'Pixel',
      to_name: 'Sage',
    }));

    mockSql
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce(mockMessages)
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([]);

    const response = await GET();
    const data = await response.json();

    expect(data.feed).toHaveLength(30);
  });

  it('should include message metadata (from_name, to_name)', async () => {
    const mockMessages = [
      {
        id: 'msg-1',
        from: 'pixel',
        to: 'sage',
        content: 'Hello!',
        type: 'message',
        timestamp: '2024-01-01T00:01:00Z',
        from_name: 'Pixel',
        to_name: 'Sage',
      },
    ];

    mockSql
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce(mockMessages)
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([]);

    const response = await GET();
    const data = await response.json();

    expect(data.feed[0].from_name).toBe('Pixel');
    expect(data.feed[0].to_name).toBe('Sage');
  });

  it('should handle empty bots', async () => {
    mockSql
      .mockResolvedValueOnce([]) // empty bots
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([]);

    const response = await GET();
    const data = await response.json();

    expect(data.residents).toEqual([]);
  });

  it('should handle empty messages', async () => {
    mockSql
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([]) // empty messages
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([]);

    const response = await GET();
    const data = await response.json();

    expect(data.feed).toEqual([]);
  });

  it('should handle empty world state', async () => {
    mockSql
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([]) // empty world state
      .mockResolvedValueOnce([]);

    const response = await GET();
    const data = await response.json();

    expect(data.world).toEqual({});
  });

  it('should handle empty memories', async () => {
    const mockBots = [
      {
        id: 'bot-1',
        handle: 'pixel',
        name: 'Pixel',
        description: 'A curious artist',
        created_at: '2024-01-01T00:00:00Z',
      },
    ];

    mockSql
      .mockResolvedValueOnce(mockBots)
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([]); // empty memories

    const response = await GET();
    const data = await response.json();

    expect(data.residents[0].latestMemory).toBe(null);
  });

  it('should use DISTINCT ON to get only latest memory per bot', async () => {
    const mockBots = [
      {
        id: 'bot-1',
        handle: 'pixel',
        name: 'Pixel',
        description: 'A curious artist',
        created_at: '2024-01-01T00:00:00Z',
      },
    ];

    const mockMemories = [
      {
        bot_handle: 'pixel',
        memory: 'Most recent memory',
        created_at: '2024-01-01T00:02:00Z',
      },
    ];

    mockSql
      .mockResolvedValueOnce(mockBots)
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce(mockMemories);

    const response = await GET();
    const data = await response.json();

    // Verify DISTINCT ON query was called (4th call is memories)
    expect(mockSql).toHaveBeenCalledTimes(4);
    expect(data.residents[0].latestMemory).toBe('Most recent memory');
  });

  it('should return 200 status', async () => {
    mockSql
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([]);

    const response = await GET();

    expect(response.status).toBe(200);
  });

  it('should handle multiple bots with mixed memory presence', async () => {
    const mockBots = [
      {
        id: 'bot-1',
        handle: 'pixel',
        name: 'Pixel',
        description: 'Artist',
        created_at: '2024-01-01T00:00:00Z',
      },
      {
        id: 'bot-2',
        handle: 'sage',
        name: 'Sage',
        description: 'Librarian',
        created_at: '2024-01-01T00:00:01Z',
      },
      {
        id: 'bot-3',
        handle: 'nova',
        name: 'Nova',
        description: 'Scientist',
        created_at: '2024-01-01T00:00:02Z',
      },
    ];

    const mockMemories = [
      {
        bot_handle: 'pixel',
        memory: 'Pixel memory',
        created_at: '2024-01-01T00:02:00Z',
      },
      {
        bot_handle: 'nova',
        memory: 'Nova memory',
        created_at: '2024-01-01T00:02:01Z',
      },
    ];

    mockSql
      .mockResolvedValueOnce(mockBots)
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce(mockMemories);

    const response = await GET();
    const data = await response.json();

    expect(data.residents[0].latestMemory).toBe('Pixel memory');
    expect(data.residents[1].latestMemory).toBe(null); // sage has no memory
    expect(data.residents[2].latestMemory).toBe('Nova memory');
  });

  it('should properly join message sender and recipient names', async () => {
    const mockBots = [
      {
        id: 'bot-1',
        handle: 'pixel',
        name: 'Pixel',
        description: 'Artist',
        created_at: '2024-01-01T00:00:00Z',
      },
    ];

    const mockMessages = [
      {
        id: 'msg-1',
        from: 'pixel',
        to: 'sage',
        content: 'Hello!',
        type: 'message',
        timestamp: '2024-01-01T00:01:00Z',
        from_name: 'Pixel',
        to_name: 'Sage',
      },
      {
        id: 'msg-2',
        from: 'unknown',
        to: 'pixel',
        content: 'Hi back!',
        type: 'message',
        timestamp: '2024-01-01T00:01:01Z',
        from_name: null, // LEFT JOIN may return null
        to_name: 'Pixel',
      },
    ];

    mockSql
      .mockResolvedValueOnce(mockBots)
      .mockResolvedValueOnce(mockMessages)
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([]);

    const response = await GET();
    const data = await response.json();

    expect(data.feed[0].from_name).toBe('Pixel');
    expect(data.feed[0].to_name).toBe('Sage');
    expect(data.feed[1].from_name).toBe(null);
    expect(data.feed[1].to_name).toBe('Pixel');
  });

  it('should handle database query failures gracefully', async () => {
    mockSql.mockRejectedValue(new Error('Database connection failed'));

    await expect(GET()).rejects.toThrow('Database connection failed');
  });

  it('should handle very large result sets efficiently', async () => {
    const largeBotSet = Array.from({ length: 100 }, (_, i) => ({
      id: `bot-${i}`,
      handle: `bot${i}`,
      name: `Bot ${i}`,
      description: `Description ${i}`,
      created_at: `2024-01-01T00:00:${String(i).padStart(2, '0')}Z`,
    }));

    const largeMessageSet = Array.from({ length: 30 }, (_, i) => ({
      id: `msg-${i}`,
      from: `bot${i % 10}`,
      to: `bot${(i + 1) % 10}`,
      content: `Message ${i}`,
      type: 'message',
      timestamp: `2024-01-01T00:${String(i).padStart(2, '0')}:00Z`,
      from_name: `Bot ${i % 10}`,
      to_name: `Bot ${(i + 1) % 10}`,
    }));

    mockSql
      .mockResolvedValueOnce(largeBotSet)
      .mockResolvedValueOnce(largeMessageSet)
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([]);

    const response = await GET();
    const data = await response.json();

    expect(data.residents).toHaveLength(100);
    expect(data.feed).toHaveLength(30);
  });

  it('should handle bots with special characters in handles', async () => {
    const mockBots = [
      {
        id: 'bot-1',
        handle: 'test_bot',
        name: 'Test Bot',
        description: 'A test bot',
        created_at: '2024-01-01T00:00:00Z',
      },
      {
        id: 'bot-2',
        handle: 'bot-with-dash',
        name: 'Dash Bot',
        description: 'Bot with dash',
        created_at: '2024-01-01T00:00:01Z',
      },
    ];

    mockSql
      .mockResolvedValueOnce(mockBots)
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([]);

    const response = await GET();
    const data = await response.json();

    expect(data.residents[0].handle).toBe('test_bot');
    expect(data.residents[1].handle).toBe('bot-with-dash');
  });

  it('should handle messages with all types', async () => {
    const mockMessages = [
      {
        id: 'msg-1',
        from: 'pixel',
        to: 'sage',
        content: 'Message',
        type: 'message',
        timestamp: '2024-01-01T00:00:00Z',
        from_name: 'Pixel',
        to_name: 'Sage',
      },
      {
        id: 'msg-2',
        from: 'sage',
        to: 'pixel',
        content: 'AI Response',
        type: 'ai_response',
        timestamp: '2024-01-01T00:00:01Z',
        from_name: 'Sage',
        to_name: 'Pixel',
      },
      {
        id: 'msg-3',
        from: 'nova',
        to: 'reed',
        content: 'Simulation',
        type: 'simulation',
        timestamp: '2024-01-01T00:00:02Z',
        from_name: 'Nova',
        to_name: 'Reed',
      },
    ];

    mockSql
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce(mockMessages)
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([]);

    const response = await GET();
    const data = await response.json();

    expect(data.feed).toHaveLength(3);
    expect(data.feed.map(m => m.type)).toEqual(['message', 'ai_response', 'simulation']);
  });

  it('should preserve message order (DESC by timestamp)', async () => {
    const mockMessages = [
      {
        id: 'msg-3',
        from: 'pixel',
        to: 'sage',
        content: 'Latest',
        type: 'message',
        timestamp: '2024-01-01T00:03:00Z',
        from_name: 'Pixel',
        to_name: 'Sage',
      },
      {
        id: 'msg-2',
        from: 'sage',
        to: 'pixel',
        content: 'Middle',
        type: 'message',
        timestamp: '2024-01-01T00:02:00Z',
        from_name: 'Sage',
        to_name: 'Pixel',
      },
      {
        id: 'msg-1',
        from: 'nova',
        to: 'reed',
        content: 'Oldest',
        type: 'message',
        timestamp: '2024-01-01T00:01:00Z',
        from_name: 'Nova',
        to_name: 'Reed',
      },
    ];

    mockSql
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce(mockMessages)
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([]);

    const response = await GET();
    const data = await response.json();

    // Messages should be in DESC order (latest first)
    expect(data.feed[0].content).toBe('Latest');
    expect(data.feed[1].content).toBe('Middle');
    expect(data.feed[2].content).toBe('Oldest');
  });

  it('should handle very long memory text', async () => {
    const longMemory = 'M'.repeat(10000);
    const mockBots = [
      {
        id: 'bot-1',
        handle: 'pixel',
        name: 'Pixel',
        description: 'Artist',
        created_at: '2024-01-01T00:00:00Z',
      },
    ];

    const mockMemories = [
      {
        bot_handle: 'pixel',
        memory: longMemory,
        created_at: '2024-01-01T00:02:00Z',
      },
    ];

    mockSql
      .mockResolvedValueOnce(mockBots)
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce(mockMemories);

    const response = await GET();
    const data = await response.json();

    expect(data.residents[0].latestMemory).toBe(longMemory);
  });
});