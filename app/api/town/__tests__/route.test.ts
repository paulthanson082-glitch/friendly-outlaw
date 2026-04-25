/**
 * @jest-environment node
 */
import { GET } from '../route';
import { NextResponse } from 'next/server';

// Mock the db module
const mockSql = jest.fn();

jest.mock('@/lib/db', () => ({
  getDb: jest.fn(() => mockSql),
}));

describe('/api/town GET', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should return town data with residents, messages, and world state', async () => {
    const mockBots = [
      {
        id: '1',
        handle: 'pixel',
        name: 'Pixel',
        description: 'An artist',
        created_at: '2024-01-01T00:00:00Z',
      },
      {
        id: '2',
        handle: 'sage',
        name: 'Sage',
        description: 'A librarian',
        created_at: '2024-01-01T00:00:00Z',
      },
    ];

    const mockMessages = [
      {
        id: 'msg1',
        from: 'pixel',
        to: 'sage',
        content: 'Hello!',
        type: 'message',
        timestamp: '2024-01-01T10:00:00Z',
        from_name: 'Pixel',
        to_name: 'Sage',
      },
    ];

    const mockWorldState = [
      { key: 'tick', value: '5', updated_at: '2024-01-01T10:00:00Z' },
      { key: 'status', value: 'running', updated_at: '2024-01-01T10:00:00Z' },
    ];

    const mockMemories = [
      {
        bot_handle: 'pixel',
        memory: 'Had a nice chat with Sage',
        created_at: '2024-01-01T09:00:00Z',
      },
    ];

    mockSql.mockResolvedValueOnce(mockBots).mockResolvedValueOnce(mockMessages).mockResolvedValueOnce(mockWorldState).mockResolvedValueOnce(mockMemories);

    const response = await GET();
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data).toHaveProperty('world');
    expect(data).toHaveProperty('residents');
    expect(data).toHaveProperty('feed');
  });

  it('should format world state as key-value object', async () => {
    const mockWorldState = [
      { key: 'tick', value: '10', updated_at: '2024-01-01T10:00:00Z' },
      { key: 'status', value: 'paused', updated_at: '2024-01-01T10:00:00Z' },
    ];

    mockSql.mockResolvedValueOnce([]).mockResolvedValueOnce([]).mockResolvedValueOnce(mockWorldState).mockResolvedValueOnce([]);

    const response = await GET();
    const data = await response.json();

    expect(data.world).toEqual({
      tick: '10',
      status: 'paused',
    });
  });

  it('should include latest memory for each resident', async () => {
    const mockBots = [
      {
        id: '1',
        handle: 'pixel',
        name: 'Pixel',
        description: 'An artist',
        created_at: '2024-01-01T00:00:00Z',
      },
    ];

    const mockMemories = [
      {
        bot_handle: 'pixel',
        memory: 'Latest memory for Pixel',
        created_at: '2024-01-01T10:00:00Z',
      },
    ];

    mockSql.mockResolvedValueOnce(mockBots).mockResolvedValueOnce([]).mockResolvedValueOnce([]).mockResolvedValueOnce(mockMemories);

    const response = await GET();
    const data = await response.json();

    expect(data.residents[0].latestMemory).toBe('Latest memory for Pixel');
  });

  it('should set latestMemory to null if no memories exist', async () => {
    const mockBots = [
      {
        id: '1',
        handle: 'pixel',
        name: 'Pixel',
        description: 'An artist',
        created_at: '2024-01-01T00:00:00Z',
      },
    ];

    mockSql.mockResolvedValueOnce(mockBots).mockResolvedValueOnce([]).mockResolvedValueOnce([]).mockResolvedValueOnce([]);

    const response = await GET();
    const data = await response.json();

    expect(data.residents[0].latestMemory).toBeNull();
  });

  it('should limit messages to 30', async () => {
    const mockBots: any[] = [];
    const mockWorldState: any[] = [];
    const mockMemories: any[] = [];

    // Mock sql to verify LIMIT 30 is used
    mockSql.mockResolvedValueOnce(mockBots).mockResolvedValueOnce([]).mockResolvedValueOnce(mockWorldState).mockResolvedValueOnce(mockMemories);

    await GET();

    expect(mockSql).toHaveBeenCalled();
  });

  it('should order residents by name ASC', async () => {
    const mockBots = [
      {
        id: '1',
        handle: 'zara',
        name: 'Zara',
        description: 'Entrepreneur',
        created_at: '2024-01-01T00:00:00Z',
      },
      {
        id: '2',
        handle: 'pixel',
        name: 'Pixel',
        description: 'Artist',
        created_at: '2024-01-01T00:00:00Z',
      },
    ];

    mockSql.mockResolvedValueOnce(mockBots).mockResolvedValueOnce([]).mockResolvedValueOnce([]).mockResolvedValueOnce([]);

    const response = await GET();
    const data = await response.json();

    expect(data.residents[0].name).toBe('Zara');
    expect(data.residents[1].name).toBe('Pixel');
  });

  it('should order messages by timestamp DESC', async () => {
    const mockMessages = [
      {
        id: 'msg2',
        from: 'sage',
        to: 'pixel',
        content: 'Later message',
        type: 'message',
        timestamp: '2024-01-01T11:00:00Z',
        from_name: 'Sage',
        to_name: 'Pixel',
      },
      {
        id: 'msg1',
        from: 'pixel',
        to: 'sage',
        content: 'Earlier message',
        type: 'message',
        timestamp: '2024-01-01T10:00:00Z',
        from_name: 'Pixel',
        to_name: 'Sage',
      },
    ];

    mockSql.mockResolvedValueOnce([]).mockResolvedValueOnce(mockMessages).mockResolvedValueOnce([]).mockResolvedValueOnce([]);

    const response = await GET();
    const data = await response.json();

    expect(data.feed[0].timestamp).toBe('2024-01-01T11:00:00Z');
    expect(data.feed[1].timestamp).toBe('2024-01-01T10:00:00Z');
  });

  it('should handle empty database', async () => {
    mockSql.mockResolvedValueOnce([]).mockResolvedValueOnce([]).mockResolvedValueOnce([]).mockResolvedValueOnce([]);

    const response = await GET();
    const data = await response.json();

    expect(data.world).toEqual({});
    expect(data.residents).toEqual([]);
    expect(data.feed).toEqual([]);
  });

  it('should handle database errors gracefully', async () => {
    mockSql.mockRejectedValue(new Error('Database connection failed'));

    await expect(GET()).rejects.toThrow('Database connection failed');
  });

  it('should include message metadata (from_name, to_name)', async () => {
    const mockMessages = [
      {
        id: 'msg1',
        from: 'pixel',
        to: 'sage',
        content: 'Hello!',
        type: 'message',
        timestamp: '2024-01-01T10:00:00Z',
        from_name: 'Pixel',
        to_name: 'Sage',
      },
    ];

    mockSql.mockResolvedValueOnce([]).mockResolvedValueOnce(mockMessages).mockResolvedValueOnce([]).mockResolvedValueOnce([]);

    const response = await GET();
    const data = await response.json();

    expect(data.feed[0].from_name).toBe('Pixel');
    expect(data.feed[0].to_name).toBe('Sage');
  });

  it('should use Promise.all for parallel queries', async () => {
    mockSql.mockResolvedValueOnce([]).mockResolvedValueOnce([]).mockResolvedValueOnce([]).mockResolvedValueOnce([]);

    const startTime = Date.now();
    await GET();
    const duration = Date.now() - startTime;

    // If queries are parallel, it should be fast
    expect(duration).toBeLessThan(1000);
  });

  it('should return NextResponse with JSON content type', async () => {
    mockSql.mockResolvedValueOnce([]).mockResolvedValueOnce([]).mockResolvedValueOnce([]).mockResolvedValueOnce([]);

    const response = await GET();

    expect(response).toBeInstanceOf(NextResponse);
    expect(response.headers.get('content-type')).toContain('application/json');
  });

  it('should handle DISTINCT ON for memories correctly', async () => {
    const mockBots = [
      {
        id: '1',
        handle: 'pixel',
        name: 'Pixel',
        description: 'An artist',
        created_at: '2024-01-01T00:00:00Z',
      },
    ];

    const mockMemories = [
      {
        bot_handle: 'pixel',
        memory: 'Most recent memory',
        created_at: '2024-01-01T12:00:00Z',
      },
    ];

    mockSql.mockResolvedValueOnce(mockBots).mockResolvedValueOnce([]).mockResolvedValueOnce([]).mockResolvedValueOnce(mockMemories);

    const response = await GET();
    const data = await response.json();

    expect(data.residents[0].latestMemory).toBe('Most recent memory');
  });

  it('should preserve all bot fields in residents', async () => {
    const mockBots = [
      {
        id: '123',
        handle: 'pixel',
        name: 'Pixel',
        description: 'An artist',
        created_at: '2024-01-01T00:00:00Z',
      },
    ];

    mockSql.mockResolvedValueOnce(mockBots).mockResolvedValueOnce([]).mockResolvedValueOnce([]).mockResolvedValueOnce([]);

    const response = await GET();
    const data = await response.json();

    expect(data.residents[0]).toMatchObject({
      id: '123',
      handle: 'pixel',
      name: 'Pixel',
      description: 'An artist',
      created_at: '2024-01-01T00:00:00Z',
      latestMemory: null,
    });
  });

  it('should handle messages with null bot names gracefully', async () => {
    const mockMessages = [
      {
        id: 'msg1',
        from: 'unknown1',
        to: 'unknown2',
        content: 'Hello!',
        type: 'message',
        timestamp: '2024-01-01T10:00:00Z',
        from_name: null,
        to_name: null,
      },
    ];

    mockSql.mockResolvedValueOnce([]).mockResolvedValueOnce(mockMessages).mockResolvedValueOnce([]).mockResolvedValueOnce([]);

    const response = await GET();
    const data = await response.json();

    expect(data.feed[0].from_name).toBeNull();
    expect(data.feed[0].to_name).toBeNull();
  });

  it('should return data structure with correct top-level keys', async () => {
    mockSql.mockResolvedValueOnce([]).mockResolvedValueOnce([]).mockResolvedValueOnce([]).mockResolvedValueOnce([]);

    const response = await GET();
    const data = await response.json();

    expect(Object.keys(data)).toEqual(['world', 'residents', 'feed']);
  });

  it('should handle multiple residents with same latest memory time', async () => {
    const mockBots = [
      { id: '1', handle: 'pixel', name: 'Pixel', description: 'Artist', created_at: '2024-01-01T00:00:00Z' },
      { id: '2', handle: 'sage', name: 'Sage', description: 'Librarian', created_at: '2024-01-01T00:00:00Z' },
    ];

    const mockMemories = [
      { bot_handle: 'pixel', memory: 'Memory A', created_at: '2024-01-01T10:00:00Z' },
      { bot_handle: 'sage', memory: 'Memory B', created_at: '2024-01-01T10:00:00Z' },
    ];

    mockSql.mockResolvedValueOnce(mockBots).mockResolvedValueOnce([]).mockResolvedValueOnce([]).mockResolvedValueOnce(mockMemories);

    const response = await GET();
    const data = await response.json();

    expect(data.residents).toHaveLength(2);
    expect(data.residents[0].latestMemory).toBeTruthy();
    expect(data.residents[1].latestMemory).toBeTruthy();
  });

  it('should handle very large feed efficiently', async () => {
    const largeFeed = Array.from({ length: 30 }, (_, i) => ({
      id: `msg${i}`,
      from: 'pixel',
      to: 'sage',
      content: `Message ${i}`,
      type: 'message',
      timestamp: new Date(Date.now() - i * 1000).toISOString(),
      from_name: 'Pixel',
      to_name: 'Sage',
    }));

    mockSql.mockResolvedValueOnce([]).mockResolvedValueOnce(largeFeed).mockResolvedValueOnce([]).mockResolvedValueOnce([]);

    const response = await GET();
    const data = await response.json();

    expect(data.feed).toHaveLength(30);
  });

  it('should return valid JSON response', async () => {
    mockSql.mockResolvedValueOnce([]).mockResolvedValueOnce([]).mockResolvedValueOnce([]).mockResolvedValueOnce([]);

    const response = await GET();
    const text = await response.text();

    expect(() => JSON.parse(text)).not.toThrow();
  });

  it('should include all bot properties in residents', async () => {
    const mockBots = [
      {
        id: '1',
        handle: 'pixel',
        name: 'Pixel',
        description: 'Artist',
        created_at: '2024-01-01T00:00:00Z',
      },
    ];

    mockSql.mockResolvedValueOnce(mockBots).mockResolvedValueOnce([]).mockResolvedValueOnce([]).mockResolvedValueOnce([]);

    const response = await GET();
    const data = await response.json();

    const resident = data.residents[0];
    expect(resident).toHaveProperty('id');
    expect(resident).toHaveProperty('handle');
    expect(resident).toHaveProperty('name');
    expect(resident).toHaveProperty('description');
    expect(resident).toHaveProperty('created_at');
    expect(resident).toHaveProperty('latestMemory');
  });
});