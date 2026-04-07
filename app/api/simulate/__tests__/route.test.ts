import { POST, GET, PATCH } from '../route';
import { NextRequest } from 'next/server';

// Mock the db module
const mockSql = jest.fn();

jest.mock('@/lib/db', () => ({
  getDb: jest.fn(() => mockSql),
}));

// Mock the ai module
jest.mock('@/lib/ai', () => ({
  generateBotResponse: jest.fn().mockResolvedValue('Simulated response'),
  generateMemory: jest.fn().mockResolvedValue('Simulated memory'),
}));

// Mock Math.random for predictable tests
const originalRandom = Math.random;

describe('/api/simulate', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    Math.random = originalRandom;
  });

  const createMockRequest = (body: any) => {
    return {
      json: async () => body,
    } as NextRequest;
  };

  describe('POST', () => {
    it('should return 409 if simulation is paused', async () => {
      mockSql.mockResolvedValueOnce([{ value: 'paused' }]);

      const request = createMockRequest({});
      const response = await POST(request);
      const data = await response.json();

      expect(response.status).toBe(409);
      expect(data.error).toContain('paused');
    });

    it('should return 400 if less than 2 bots exist', async () => {
      mockSql
        .mockResolvedValueOnce([{ value: 'running' }])
        .mockResolvedValueOnce([{ handle: 'pixel' }]); // Only 1 bot

      const request = createMockRequest({});
      const response = await POST(request);
      const data = await response.json();

      expect(response.status).toBe(400);
      expect(data.error).toContain('at least 2 bots');
    });

    it('should run simulation with default 1 exchange', async () => {
      const mockBots = [
        { handle: 'pixel' },
        { handle: 'sage' },
      ];

      mockSql
        .mockResolvedValueOnce([{ value: 'running' }])
        .mockResolvedValueOnce(mockBots)
        .mockResolvedValueOnce([]) // Messages
        .mockResolvedValueOnce([]) // Memories
        .mockResolvedValueOnce([]) // Insert message
        .mockResolvedValueOnce([]) // Update tick
        .mockResolvedValueOnce([{ value: '1' }]); // Get tick

      const request = createMockRequest({});
      const response = await POST(request);
      const data = await response.json();

      expect(response.status).toBe(200);
      expect(data.generated).toHaveLength(1);
    });

    it('should limit exchanges to maximum of 3', async () => {
      const mockBots = [
        { handle: 'pixel' },
        { handle: 'sage' },
        { handle: 'nova' },
      ];

      mockSql
        .mockResolvedValueOnce([{ value: 'running' }])
        .mockResolvedValueOnce(mockBots);

      // Mock for 3 exchanges
      for (let i = 0; i < 3; i++) {
        mockSql
          .mockResolvedValueOnce([]) // Messages
          .mockResolvedValueOnce([]) // Memories
          .mockResolvedValueOnce([]); // Insert
      }

      mockSql
        .mockResolvedValueOnce([]) // Update tick
        .mockResolvedValueOnce([{ value: '1' }]); // Get tick

      const request = createMockRequest({ exchanges: 10 }); // Request 10 but should cap at 3
      const response = await POST(request);
      const data = await response.json();

      expect(data.generated).toHaveLength(3);
    });

    it('should allow specifying number of exchanges', async () => {
      const mockBots = [
        { handle: 'pixel' },
        { handle: 'sage' },
      ];

      mockSql
        .mockResolvedValueOnce([{ value: 'running' }])
        .mockResolvedValueOnce(mockBots);

      // Mock for 2 exchanges
      for (let i = 0; i < 2; i++) {
        mockSql
          .mockResolvedValueOnce([])
          .mockResolvedValueOnce([])
          .mockResolvedValueOnce([]);
      }

      mockSql
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([{ value: '2' }]);

      const request = createMockRequest({ exchanges: 2 });
      const response = await POST(request);
      const data = await response.json();

      expect(data.generated).toHaveLength(2);
    });

    it('should pick random bots for each exchange', async () => {
      const mockBots = [
        { handle: 'pixel' },
        { handle: 'sage' },
        { handle: 'nova' },
      ];

      mockSql
        .mockResolvedValueOnce([{ value: 'running' }])
        .mockResolvedValueOnce(mockBots)
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([{ value: '1' }]);

      const request = createMockRequest({});
      const response = await POST(request);
      const data = await response.json();

      expect(data.generated[0]).toHaveProperty('from');
      expect(data.generated[0]).toHaveProperty('to');
      expect(data.generated[0].from).not.toBe(data.generated[0].to);
    });

    it('should call generateBotResponse for each exchange', async () => {
      const { generateBotResponse } = require('@/lib/ai');
      const mockBots = [{ handle: 'pixel' }, { handle: 'sage' }];

      mockSql
        .mockResolvedValueOnce([{ value: 'running' }])
        .mockResolvedValueOnce(mockBots)
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([{ value: '1' }]);

      const request = createMockRequest({});
      await POST(request);

      expect(generateBotResponse).toHaveBeenCalled();
    });

    it('should store message with type "simulation"', async () => {
      const mockBots = [{ handle: 'pixel' }, { handle: 'sage' }];

      mockSql
        .mockResolvedValueOnce([{ value: 'running' }])
        .mockResolvedValueOnce(mockBots)
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([{ value: '1' }]);

      const request = createMockRequest({});
      await POST(request);

      const insertCalls = mockSql.mock.calls.filter(call =>
        call[0]?.some?.((str: string) => str.includes('INSERT INTO messages'))
      );
      expect(insertCalls.length).toBeGreaterThan(0);
    });

    it('should generate memory with 40% probability', async () => {
      const { generateMemory } = require('@/lib/ai');
      const mockBots = [{ handle: 'pixel' }, { handle: 'sage' }];

      // Force Math.random to return 0.3 (< 0.4, should generate memory)
      Math.random = jest.fn().mockReturnValue(0.3);

      mockSql
        .mockResolvedValueOnce([{ value: 'running' }])
        .mockResolvedValueOnce(mockBots)
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([]) // Memory insert
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([{ value: '1' }]);

      const request = createMockRequest({});
      await POST(request);

      expect(generateMemory).toHaveBeenCalled();
    });

    it('should not generate memory with 60% probability', async () => {
      const { generateMemory } = require('@/lib/ai');
      const mockBots = [{ handle: 'pixel' }, { handle: 'sage' }];

      // Force Math.random to return 0.5 (>= 0.4, should not generate memory)
      Math.random = jest.fn().mockReturnValue(0.5);

      mockSql
        .mockResolvedValueOnce([{ value: 'running' }])
        .mockResolvedValueOnce(mockBots)
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([{ value: '1' }]);

      const request = createMockRequest({});
      await POST(request);

      expect(generateMemory).not.toHaveBeenCalled();
    });

    it('should increment world tick', async () => {
      const mockBots = [{ handle: 'pixel' }, { handle: 'sage' }];

      mockSql
        .mockResolvedValueOnce([{ value: 'running' }])
        .mockResolvedValueOnce(mockBots)
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([{ value: '5' }]);

      const request = createMockRequest({});
      const response = await POST(request);
      const data = await response.json();

      expect(data.tick).toBe(5);
    });

    it('should handle memory generation errors gracefully', async () => {
      const { generateMemory } = require('@/lib/ai');
      generateMemory.mockRejectedValueOnce(new Error('Memory error'));

      const mockBots = [{ handle: 'pixel' }, { handle: 'sage' }];
      Math.random = jest.fn().mockReturnValue(0.3);

      mockSql
        .mockResolvedValueOnce([{ value: 'running' }])
        .mockResolvedValueOnce(mockBots)
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([{ value: '1' }]);

      const request = createMockRequest({});
      const response = await POST(request);

      expect(response.status).toBe(200);
    });

    it('should handle invalid JSON body gracefully', async () => {
      const request = {
        json: async () => {
          throw new Error('Invalid JSON');
        },
      } as NextRequest;

      mockSql
        .mockResolvedValueOnce([{ value: 'running' }])
        .mockResolvedValueOnce([{ handle: 'pixel' }, { handle: 'sage' }])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([{ value: '1' }]);

      const response = await POST(request);
      expect(response.status).toBe(200);
    });

    it('should return generated messages in response', async () => {
      const { generateBotResponse } = require('@/lib/ai');
      generateBotResponse.mockResolvedValueOnce('Test message content');

      const mockBots = [{ handle: 'pixel' }, { handle: 'sage' }];

      mockSql
        .mockResolvedValueOnce([{ value: 'running' }])
        .mockResolvedValueOnce(mockBots)
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([{ value: '1' }]);

      const request = createMockRequest({});
      const response = await POST(request);
      const data = await response.json();

      expect(data.generated[0].content).toBe('Test message content');
    });
  });

  describe('GET', () => {
    it('should return current world state', async () => {
      const mockState = [
        { key: 'tick', value: '10', updated_at: '2024-01-01T10:00:00Z' },
        { key: 'status', value: 'running', updated_at: '2024-01-01T10:00:00Z' },
      ];

      mockSql.mockResolvedValueOnce(mockState);

      const response = await GET();
      const data = await response.json();

      expect(data).toEqual({
        tick: '10',
        status: 'running',
      });
    });

    it('should handle empty world state', async () => {
      mockSql.mockResolvedValueOnce([]);

      const response = await GET();
      const data = await response.json();

      expect(data).toEqual({});
    });

    it('should format state as key-value pairs', async () => {
      const mockState = [
        { key: 'custom_key', value: 'custom_value', updated_at: '2024-01-01T10:00:00Z' },
      ];

      mockSql.mockResolvedValueOnce(mockState);

      const response = await GET();
      const data = await response.json();

      expect(data.custom_key).toBe('custom_value');
    });
  });

  describe('PATCH', () => {
    it('should pause simulation', async () => {
      mockSql.mockResolvedValueOnce([]);

      const request = createMockRequest({ action: 'pause' });
      const response = await PATCH(request);
      const data = await response.json();

      expect(response.status).toBe(200);
      expect(data.status).toBe('paused');
    });

    it('should resume simulation', async () => {
      mockSql.mockResolvedValueOnce([]);

      const request = createMockRequest({ action: 'resume' });
      const response = await PATCH(request);
      const data = await response.json();

      expect(response.status).toBe(200);
      expect(data.status).toBe('running');
    });

    it('should return 400 for invalid action', async () => {
      const request = createMockRequest({ action: 'invalid' });
      const response = await PATCH(request);
      const data = await response.json();

      expect(response.status).toBe(400);
      expect(data.error).toContain('pause');
      expect(data.error).toContain('resume');
    });

    it('should update world_state in database', async () => {
      mockSql.mockResolvedValueOnce([]);

      const request = createMockRequest({ action: 'pause' });
      await PATCH(request);

      const updateCalls = mockSql.mock.calls.filter(call =>
        call[0]?.some?.((str: string) => str.includes('UPDATE world_state'))
      );
      expect(updateCalls.length).toBeGreaterThan(0);
    });

    it('should handle missing action parameter', async () => {
      const request = createMockRequest({});
      const response = await PATCH(request);
      const data = await response.json();

      expect(response.status).toBe(400);
      expect(data.error).toBeDefined();
    });
  });

  describe('Integration scenarios', () => {
    it('should ensure speaker and listener are different bots', async () => {
      const mockBots = [
        { handle: 'pixel' },
        { handle: 'sage' },
        { handle: 'nova' },
      ];

      let capturedSpeaker: string | null = null;
      let capturedListener: string | null = null;

      const { generateBotResponse } = require('@/lib/ai');
      generateBotResponse.mockImplementation((speaker: string, listener: string) => {
        capturedSpeaker = speaker;
        capturedListener = listener;
        return Promise.resolve('Response');
      });

      mockSql
        .mockResolvedValueOnce([{ value: 'running' }])
        .mockResolvedValueOnce(mockBots)
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([{ value: '1' }]);

      const request = createMockRequest({});
      await POST(request);

      expect(capturedSpeaker).not.toBe(capturedListener);
      expect(capturedSpeaker).toBeTruthy();
      expect(capturedListener).toBeTruthy();
    });

    it('should return current tick number after incrementing', async () => {
      const mockBots = [{ handle: 'pixel' }, { handle: 'sage' }];

      mockSql
        .mockResolvedValueOnce([{ value: 'running' }])
        .mockResolvedValueOnce(mockBots)
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([{ value: '42' }]);

      const request = createMockRequest({});
      const response = await POST(request);
      const data = await response.json();

      expect(data.tick).toBe(42);
    });

    it('should handle database errors when fetching bots', async () => {
      mockSql
        .mockResolvedValueOnce([{ value: 'running' }])
        .mockRejectedValueOnce(new Error('Failed to fetch bots'));

      const request = createMockRequest({});

      await expect(POST(request)).rejects.toThrow('Failed to fetch bots');
    });

    it('should fetch messages and memories for each exchange', async () => {
      const mockBots = [{ handle: 'pixel' }, { handle: 'sage' }];

      mockSql
        .mockResolvedValueOnce([{ value: 'running' }])
        .mockResolvedValueOnce(mockBots)
        .mockResolvedValueOnce([]) // Messages
        .mockResolvedValueOnce([]) // Memories
        .mockResolvedValueOnce([]) // Insert
        .mockResolvedValueOnce([]) // Update tick
        .mockResolvedValueOnce([{ value: '1' }]); // Get tick

      const request = createMockRequest({});
      await POST(request);

      const messagesCalls = mockSql.mock.calls.filter(call =>
        call[0]?.some?.((str: string) => str.includes('FROM messages'))
      );
      const memoriesCalls = mockSql.mock.calls.filter(call =>
        call[0]?.some?.((str: string) => str.includes('FROM bot_memories'))
      );

      expect(messagesCalls.length).toBeGreaterThan(0);
      expect(memoriesCalls.length).toBeGreaterThan(0);
    });
  });

  describe('POST edge cases', () => {
    it('should treat exchanges=0 as zero exchanges and still return tick', async () => {
      // Math.min(0, 3) = 0, so no exchanges run but tick still increments
      const mockBots = [{ handle: 'pixel' }, { handle: 'sage' }];

      mockSql
        .mockResolvedValueOnce([{ value: 'running' }])
        .mockResolvedValueOnce(mockBots)
        .mockResolvedValueOnce([]) // Update tick
        .mockResolvedValueOnce([{ value: '3' }]); // Get tick

      const request = createMockRequest({ exchanges: 0 });
      const response = await POST(request);
      const data = await response.json();

      expect(response.status).toBe(200);
      expect(data.generated).toHaveLength(0);
      expect(data.tick).toBe(3);
    });

    it('should handle non-numeric exchanges value by defaulting to 1', async () => {
      // Number("abc") = NaN, Math.min(NaN, 3) = NaN, so the for loop runs 0 times
      // because i < NaN is false. generated should be empty.
      const mockBots = [{ handle: 'pixel' }, { handle: 'sage' }];

      mockSql
        .mockResolvedValueOnce([{ value: 'running' }])
        .mockResolvedValueOnce(mockBots)
        .mockResolvedValueOnce([]) // Update tick
        .mockResolvedValueOnce([{ value: '1' }]);

      const request = createMockRequest({ exchanges: 'abc' });
      const response = await POST(request);

      expect(response.status).toBe(200);
    });

    it('should return tick as 0 when tick row is missing from world_state', async () => {
      const mockBots = [{ handle: 'pixel' }, { handle: 'sage' }];

      mockSql
        .mockResolvedValueOnce([{ value: 'running' }])
        .mockResolvedValueOnce(mockBots)
        .mockResolvedValueOnce([]) // Messages
        .mockResolvedValueOnce([]) // Memories
        .mockResolvedValueOnce([]) // Insert
        .mockResolvedValueOnce([]) // Update tick
        .mockResolvedValueOnce([]); // Get tick — empty result, tickRow is undefined

      const request = createMockRequest({});
      const response = await POST(request);
      const data = await response.json();

      expect(response.status).toBe(200);
      expect(data.tick).toBe(0);
    });

    it('should clamp negative exchanges to 0', async () => {
      // Math.min(-5, 3) = -5 → loop runs 0 times
      const mockBots = [{ handle: 'pixel' }, { handle: 'sage' }];

      mockSql
        .mockResolvedValueOnce([{ value: 'running' }])
        .mockResolvedValueOnce(mockBots)
        .mockResolvedValueOnce([]) // Update tick
        .mockResolvedValueOnce([{ value: '1' }]);

      const request = createMockRequest({ exchanges: -5 });
      const response = await POST(request);
      const data = await response.json();

      expect(response.status).toBe(200);
      expect(data.generated).toHaveLength(0);
    });

    it('generated entries should have from, to, and content fields', async () => {
      const { generateBotResponse } = require('@/lib/ai');
      generateBotResponse.mockResolvedValueOnce('A friendly greeting');

      const mockBots = [{ handle: 'alpha' }, { handle: 'beta' }];

      mockSql
        .mockResolvedValueOnce([{ value: 'running' }])
        .mockResolvedValueOnce(mockBots)
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([{ value: '1' }]);

      const request = createMockRequest({ exchanges: 1 });
      const response = await POST(request);
      const data = await response.json();

      expect(data.generated[0]).toHaveProperty('from');
      expect(data.generated[0]).toHaveProperty('to');
      expect(data.generated[0]).toHaveProperty('content');
      expect(typeof data.generated[0].from).toBe('string');
      expect(typeof data.generated[0].to).toBe('string');
      expect(data.generated[0].content).toBe('A friendly greeting');
    });
  });

  describe('PATCH additional cases', () => {
    it('should return 400 for action=stop (not a valid action)', async () => {
      const request = createMockRequest({ action: 'stop' });
      const response = await PATCH(request);
      const data = await response.json();

      expect(response.status).toBe(400);
      expect(data.error).toBeDefined();
    });

    it('should return 400 for action=null', async () => {
      const request = createMockRequest({ action: null });
      const response = await PATCH(request);
      const data = await response.json();

      expect(response.status).toBe(400);
    });

    it('should set status to "running" when action is resume', async () => {
      mockSql.mockResolvedValueOnce([]);

      const request = createMockRequest({ action: 'resume' });
      const response = await PATCH(request);
      const data = await response.json();

      expect(data.status).toBe('running');
    });
  });

  describe('GET additional cases', () => {
    it('should return all world state keys including custom ones', async () => {
      const mockState = [
        { key: 'tick', value: '7', updated_at: '2024-01-01T00:00:00Z' },
        { key: 'status', value: 'running', updated_at: '2024-01-01T00:00:00Z' },
        { key: 'custom', value: 'data', updated_at: '2024-01-01T00:00:00Z' },
      ];

      mockSql.mockResolvedValueOnce(mockState);

      const response = await GET();
      const data = await response.json();

      expect(Object.keys(data)).toHaveLength(3);
      expect(data.tick).toBe('7');
      expect(data.status).toBe('running');
      expect(data.custom).toBe('data');
    });

    it('should not include updated_at in the returned object', async () => {
      const mockState = [
        { key: 'tick', value: '1', updated_at: '2024-01-01T00:00:00Z' },
      ];

      mockSql.mockResolvedValueOnce(mockState);

      const response = await GET();
      const data = await response.json();

      expect(data.updated_at).toBeUndefined();
    });
  });
});