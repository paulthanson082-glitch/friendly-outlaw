import { POST, GET, PATCH } from '../route';
import { NextRequest } from 'next/server';
import * as db from '@/lib/db';
import * as ai from '@/lib/ai';

// Mock dependencies
jest.mock('@/lib/db');
jest.mock('@/lib/ai');

describe('/api/simulate', () => {
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

    mockGenerateBotResponse.mockResolvedValue('Simulated message');
    mockGenerateMemory.mockResolvedValue('Simulated memory');

    // Mock Math.random for consistent tests
    jest.spyOn(Math, 'random').mockReturnValue(0.5);
  });

  afterEach(() => {
    jest.clearAllMocks();
    jest.restoreAllMocks();
  });

  describe('POST /api/simulate', () => {
    describe('world status checks', () => {
      it('should return 409 if simulation is paused', async () => {
        mockSql.mockResolvedValueOnce([{ value: 'paused' }]); // status check

        const request = new NextRequest('http://localhost/api/simulate', {
          method: 'POST',
          body: JSON.stringify({}),
        });

        const response = await POST(request);
        const data = await response.json();

        expect(response.status).toBe(409);
        expect(data.error).toContain('Simulation is paused');
      });

      it('should proceed if simulation is running', async () => {
        mockSql
          .mockResolvedValueOnce([{ value: 'running' }]) // status
          .mockResolvedValueOnce([
            { handle: 'pixel' },
            { handle: 'sage' },
          ]) // bots
          .mockResolvedValueOnce([]) // messages
          .mockResolvedValueOnce([]) // memories
          .mockResolvedValueOnce([]) // insert message
          .mockResolvedValueOnce([]) // update tick
          .mockResolvedValueOnce([{ value: '1' }]); // get tick

        const request = new NextRequest('http://localhost/api/simulate', {
          method: 'POST',
          body: JSON.stringify({}),
        });

        const response = await POST(request);

        expect(response.status).toBe(200);
      });
    });

    describe('bot requirements', () => {
      it('should return 400 if less than 2 bots exist', async () => {
        mockSql
          .mockResolvedValueOnce([{ value: 'running' }])
          .mockResolvedValueOnce([{ handle: 'pixel' }]); // only 1 bot

        const request = new NextRequest('http://localhost/api/simulate', {
          method: 'POST',
          body: JSON.stringify({}),
        });

        const response = await POST(request);
        const data = await response.json();

        expect(response.status).toBe(400);
        expect(data.error).toContain('Need at least 2 bots to simulate');
      });

      it('should proceed with 2 or more bots', async () => {
        mockSql
          .mockResolvedValueOnce([{ value: 'running' }])
          .mockResolvedValueOnce([
            { handle: 'pixel' },
            { handle: 'sage' },
            { handle: 'nova' },
          ])
          .mockResolvedValueOnce([])
          .mockResolvedValueOnce([])
          .mockResolvedValueOnce([])
          .mockResolvedValueOnce([])
          .mockResolvedValueOnce([{ value: '1' }]);

        const request = new NextRequest('http://localhost/api/simulate', {
          method: 'POST',
          body: JSON.stringify({}),
        });

        const response = await POST(request);

        expect(response.status).toBe(200);
      });
    });

    describe('exchanges parameter', () => {
      it('should default to 1 exchange if not specified', async () => {
        mockSql
          .mockResolvedValueOnce([{ value: 'running' }])
          .mockResolvedValueOnce([
            { handle: 'pixel' },
            { handle: 'sage' },
          ])
          .mockResolvedValueOnce([])
          .mockResolvedValueOnce([])
          .mockResolvedValueOnce([])
          .mockResolvedValueOnce([])
          .mockResolvedValueOnce([{ value: '1' }]);

        const request = new NextRequest('http://localhost/api/simulate', {
          method: 'POST',
          body: JSON.stringify({}),
        });

        await POST(request);

        expect(mockGenerateBotResponse).toHaveBeenCalledTimes(1);
      });

      it('should respect exchanges parameter', async () => {
        mockSql
          .mockResolvedValueOnce([{ value: 'running' }])
          .mockResolvedValueOnce([
            { handle: 'pixel' },
            { handle: 'sage' },
          ])
          .mockResolvedValue([]); // All subsequent calls return empty

        const request = new NextRequest('http://localhost/api/simulate', {
          method: 'POST',
          body: JSON.stringify({ exchanges: 2 }),
        });

        await POST(request);

        expect(mockGenerateBotResponse).toHaveBeenCalledTimes(2);
      });

      it('should limit exchanges to maximum of 3', async () => {
        mockSql
          .mockResolvedValueOnce([{ value: 'running' }])
          .mockResolvedValueOnce([
            { handle: 'pixel' },
            { handle: 'sage' },
          ])
          .mockResolvedValue([]);

        const request = new NextRequest('http://localhost/api/simulate', {
          method: 'POST',
          body: JSON.stringify({ exchanges: 10 }),
        });

        await POST(request);

        // Should be capped at 3
        expect(mockGenerateBotResponse).toHaveBeenCalledTimes(3);
      });

      it('should handle invalid exchanges parameter', async () => {
        mockSql
          .mockResolvedValueOnce([{ value: 'running' }])
          .mockResolvedValueOnce([
            { handle: 'pixel' },
            { handle: 'sage' },
          ])
          .mockResolvedValue([]);

        const request = new NextRequest('http://localhost/api/simulate', {
          method: 'POST',
          body: JSON.stringify({ exchanges: 'invalid' }),
        });

        await POST(request);

        // Should default to 1 for NaN
        expect(mockGenerateBotResponse).toHaveBeenCalledTimes(1);
      });
    });

    describe('message generation', () => {
      beforeEach(() => {
        mockSql
          .mockResolvedValueOnce([{ value: 'running' }])
          .mockResolvedValueOnce([
            { handle: 'pixel' },
            { handle: 'sage' },
          ])
          .mockResolvedValueOnce([]) // messages
          .mockResolvedValueOnce([]) // memories
          .mockResolvedValueOnce([]) // insert
          .mockResolvedValueOnce([]) // update tick
          .mockResolvedValueOnce([{ value: '1' }]); // get tick
      });

      it('should generate messages between random bots', async () => {
        const request = new NextRequest('http://localhost/api/simulate', {
          method: 'POST',
          body: JSON.stringify({}),
        });

        await POST(request);

        expect(mockGenerateBotResponse).toHaveBeenCalled();
      });

      it('should store generated messages with type "simulation"', async () => {
        const request = new NextRequest('http://localhost/api/simulate', {
          method: 'POST',
          body: JSON.stringify({}),
        });

        await POST(request);

        const insertCall = mockSql.mock.calls.find(call =>
          call[0]?.[0]?.includes('INSERT INTO messages')
        );
        expect(insertCall).toBeDefined();
        expect(insertCall[0][0]).toContain("type = 'simulation'");
      });

      it('should return generated messages in response', async () => {
        const request = new NextRequest('http://localhost/api/simulate', {
          method: 'POST',
          body: JSON.stringify({}),
        });

        const response = await POST(request);
        const data = await response.json();

        expect(data.generated).toBeDefined();
        expect(Array.isArray(data.generated)).toBe(true);
        expect(data.generated.length).toBe(1);
        expect(data.generated[0]).toHaveProperty('from');
        expect(data.generated[0]).toHaveProperty('to');
        expect(data.generated[0]).toHaveProperty('content');
      });
    });

    describe('memory generation', () => {
      it('should generate memory 40% of the time (Math.random < 0.4)', async () => {
        jest.spyOn(Math, 'random').mockReturnValue(0.3); // < 0.4

        mockSql
          .mockResolvedValueOnce([{ value: 'running' }])
          .mockResolvedValueOnce([
            { handle: 'pixel' },
            { handle: 'sage' },
          ])
          .mockResolvedValueOnce([])
          .mockResolvedValueOnce([])
          .mockResolvedValueOnce([])
          .mockResolvedValueOnce([]) // memory insert
          .mockResolvedValueOnce([])
          .mockResolvedValueOnce([{ value: '1' }]);

        const request = new NextRequest('http://localhost/api/simulate', {
          method: 'POST',
          body: JSON.stringify({}),
        });

        await POST(request);

        expect(mockGenerateMemory).toHaveBeenCalled();
      });

      it('should not generate memory when Math.random >= 0.4', async () => {
        jest.spyOn(Math, 'random').mockReturnValue(0.5); // >= 0.4

        mockSql
          .mockResolvedValueOnce([{ value: 'running' }])
          .mockResolvedValueOnce([
            { handle: 'pixel' },
            { handle: 'sage' },
          ])
          .mockResolvedValueOnce([])
          .mockResolvedValueOnce([])
          .mockResolvedValueOnce([])
          .mockResolvedValueOnce([])
          .mockResolvedValueOnce([{ value: '1' }]);

        const request = new NextRequest('http://localhost/api/simulate', {
          method: 'POST',
          body: JSON.stringify({}),
        });

        await POST(request);

        expect(mockGenerateMemory).not.toHaveBeenCalled();
      });

      it('should not fail if memory generation fails', async () => {
        jest.spyOn(Math, 'random').mockReturnValue(0.3);
        mockGenerateMemory.mockRejectedValue(new Error('Memory error'));

        mockSql
          .mockResolvedValueOnce([{ value: 'running' }])
          .mockResolvedValueOnce([
            { handle: 'pixel' },
            { handle: 'sage' },
          ])
          .mockResolvedValueOnce([])
          .mockResolvedValueOnce([])
          .mockResolvedValueOnce([])
          .mockResolvedValueOnce([])
          .mockResolvedValueOnce([{ value: '1' }]);

        const request = new NextRequest('http://localhost/api/simulate', {
          method: 'POST',
          body: JSON.stringify({}),
        });

        const response = await POST(request);

        expect(response.status).toBe(200);
      });
    });

    describe('tick management', () => {
      beforeEach(() => {
        mockSql
          .mockResolvedValueOnce([{ value: 'running' }])
          .mockResolvedValueOnce([
            { handle: 'pixel' },
            { handle: 'sage' },
          ])
          .mockResolvedValueOnce([])
          .mockResolvedValueOnce([])
          .mockResolvedValueOnce([]);
      });

      it('should increment world tick', async () => {
        mockSql
          .mockResolvedValueOnce([]) // update tick
          .mockResolvedValueOnce([{ value: '5' }]); // get tick

        const request = new NextRequest('http://localhost/api/simulate', {
          method: 'POST',
          body: JSON.stringify({}),
        });

        await POST(request);

        const updateCall = mockSql.mock.calls.find(call =>
          call[0]?.[0]?.includes('UPDATE world_state') &&
          call[0]?.[0]?.includes('tick')
        );
        expect(updateCall).toBeDefined();
      });

      it('should return current tick in response', async () => {
        mockSql
          .mockResolvedValueOnce([])
          .mockResolvedValueOnce([{ value: '42' }]);

        const request = new NextRequest('http://localhost/api/simulate', {
          method: 'POST',
          body: JSON.stringify({}),
        });

        const response = await POST(request);
        const data = await response.json();

        expect(data.tick).toBe(42);
      });
    });

    describe('edge cases', () => {
      it('should handle malformed JSON gracefully', async () => {
        const request = new NextRequest('http://localhost/api/simulate', {
          method: 'POST',
          body: 'invalid json',
          headers: { 'Content-Type': 'application/json' },
        });

        // Should default to empty object via .catch(() => ({}))
        mockSql
          .mockResolvedValueOnce([{ value: 'running' }])
          .mockResolvedValueOnce([
            { handle: 'pixel' },
            { handle: 'sage' },
          ])
          .mockResolvedValue([]);

        const response = await POST(request);

        expect(response.status).toBe(200);
      });

      it('should handle exactly 2 bots (boundary condition)', async () => {
        mockSql
          .mockResolvedValueOnce([{ value: 'running' }])
          .mockResolvedValueOnce([
            { handle: 'pixel' },
            { handle: 'sage' },
          ]) // exactly 2 bots
          .mockResolvedValueOnce([])
          .mockResolvedValueOnce([])
          .mockResolvedValueOnce([])
          .mockResolvedValueOnce([])
          .mockResolvedValueOnce([{ value: '1' }]);

        const request = new NextRequest('http://localhost/api/simulate', {
          method: 'POST',
          body: JSON.stringify({}),
        });

        const response = await POST(request);
        const data = await response.json();

        expect(response.status).toBe(200);
        expect(data.generated).toHaveLength(1);
        expect(mockGenerateBotResponse).toHaveBeenCalledTimes(1);
      });

      it('should handle null memory from generateMemory', async () => {
        jest.spyOn(Math, 'random').mockReturnValue(0.3); // Trigger memory generation
        mockGenerateMemory.mockResolvedValue(null);

        mockSql
          .mockResolvedValueOnce([{ value: 'running' }])
          .mockResolvedValueOnce([
            { handle: 'pixel' },
            { handle: 'sage' },
          ])
          .mockResolvedValueOnce([])
          .mockResolvedValueOnce([])
          .mockResolvedValueOnce([])
          .mockResolvedValueOnce([])
          .mockResolvedValueOnce([{ value: '1' }]);

        const request = new NextRequest('http://localhost/api/simulate', {
          method: 'POST',
          body: JSON.stringify({}),
        });

        const response = await POST(request);

        expect(response.status).toBe(200);
        // Should not attempt to insert null memory
        const memoryInsertCalls = mockSql.mock.calls.filter(call =>
          call[0]?.[0]?.includes('INSERT INTO bot_memories')
        );
        expect(memoryInsertCalls.length).toBe(0);
      });
    });
  });

  describe('GET /api/simulate', () => {
    it('should return world state', async () => {
      mockSql.mockResolvedValueOnce([
        { key: 'status', value: 'running', updated_at: '2024-01-01T00:00:00Z' },
        { key: 'tick', value: '42', updated_at: '2024-01-01T00:00:01Z' },
      ]);

      const response = await GET();
      const data = await response.json();

      expect(data).toEqual({
        status: 'running',
        tick: '42',
      });
    });

    it('should handle empty world state', async () => {
      mockSql.mockResolvedValueOnce([]);

      const response = await GET();
      const data = await response.json();

      expect(data).toEqual({});
    });

    it('should include all state keys', async () => {
      mockSql.mockResolvedValueOnce([
        { key: 'status', value: 'paused', updated_at: '2024-01-01T00:00:00Z' },
        { key: 'tick', value: '100', updated_at: '2024-01-01T00:00:01Z' },
        { key: 'custom', value: 'value', updated_at: '2024-01-01T00:00:02Z' },
      ]);

      const response = await GET();
      const data = await response.json();

      expect(data).toHaveProperty('status');
      expect(data).toHaveProperty('tick');
      expect(data).toHaveProperty('custom');
    });
  });

  describe('PATCH /api/simulate', () => {
    describe('action validation', () => {
      it('should return 400 for invalid action', async () => {
        const request = new NextRequest('http://localhost/api/simulate', {
          method: 'PATCH',
          body: JSON.stringify({ action: 'invalid' }),
        });

        const response = await PATCH(request);
        const data = await response.json();

        expect(response.status).toBe(400);
        expect(data.error).toContain("action must be 'pause' or 'resume'");
      });

      it('should accept "pause" action', async () => {
        mockSql.mockResolvedValueOnce([]);

        const request = new NextRequest('http://localhost/api/simulate', {
          method: 'PATCH',
          body: JSON.stringify({ action: 'pause' }),
        });

        const response = await PATCH(request);

        expect(response.status).toBe(200);
      });

      it('should accept "resume" action', async () => {
        mockSql.mockResolvedValueOnce([]);

        const request = new NextRequest('http://localhost/api/simulate', {
          method: 'PATCH',
          body: JSON.stringify({ action: 'resume' }),
        });

        const response = await PATCH(request);

        expect(response.status).toBe(200);
      });
    });

    describe('status updates', () => {
      it('should set status to "paused" for pause action', async () => {
        mockSql.mockResolvedValueOnce([]);

        const request = new NextRequest('http://localhost/api/simulate', {
          method: 'PATCH',
          body: JSON.stringify({ action: 'pause' }),
        });

        const response = await PATCH(request);
        const data = await response.json();

        expect(data.status).toBe('paused');

        const updateCall = mockSql.mock.calls.find(call =>
          call[0]?.[0]?.includes('UPDATE world_state')
        );
        expect(updateCall).toBeDefined();
      });

      it('should set status to "running" for resume action', async () => {
        mockSql.mockResolvedValueOnce([]);

        const request = new NextRequest('http://localhost/api/simulate', {
          method: 'PATCH',
          body: JSON.stringify({ action: 'resume' }),
        });

        const response = await PATCH(request);
        const data = await response.json();

        expect(data.status).toBe('running');
      });

      it('should update the status key in world_state table', async () => {
        mockSql.mockResolvedValueOnce([]);

        const request = new NextRequest('http://localhost/api/simulate', {
          method: 'PATCH',
          body: JSON.stringify({ action: 'pause' }),
        });

        await PATCH(request);

        const updateCall = mockSql.mock.calls.find(call =>
          call[0]?.[0]?.includes("WHERE key = 'status'")
        );
        expect(updateCall).toBeDefined();
      });
    });
  });

  describe('stress testing and edge cases', () => {
    it('should handle maximum exchanges (3) with multiple bots', async () => {
      mockSql
        .mockResolvedValueOnce([{ value: 'running' }])
        .mockResolvedValueOnce([
          { handle: 'pixel' },
          { handle: 'sage' },
          { handle: 'nova' },
          { handle: 'reed' },
          { handle: 'zara' },
        ])
        .mockResolvedValue([]);

      const request = new NextRequest('http://localhost/api/simulate', {
        method: 'POST',
        body: JSON.stringify({ exchanges: 3 }),
      });

      const response = await POST(request);
      const data = await response.json();

      expect(response.status).toBe(200);
      expect(data.generated).toHaveLength(3);
      expect(mockGenerateBotResponse).toHaveBeenCalledTimes(3);
    });

    it('should handle very long generated messages', async () => {
      const longMessage = 'A'.repeat(10000);
      mockGenerateBotResponse.mockResolvedValue(longMessage);

      mockSql
        .mockResolvedValueOnce([{ value: 'running' }])
        .mockResolvedValueOnce([
          { handle: 'pixel' },
          { handle: 'sage' },
        ])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([{ value: '1' }]);

      const request = new NextRequest('http://localhost/api/simulate', {
        method: 'POST',
        body: JSON.stringify({}),
      });

      const response = await POST(request);
      const data = await response.json();

      expect(data.generated[0].content).toBe(longMessage);
    });

    it('should handle zero exchanges (defaults to 1)', async () => {
      mockSql
        .mockResolvedValueOnce([{ value: 'running' }])
        .mockResolvedValueOnce([
          { handle: 'pixel' },
          { handle: 'sage' },
        ])
        .mockResolvedValue([]);

      const request = new NextRequest('http://localhost/api/simulate', {
        method: 'POST',
        body: JSON.stringify({ exchanges: 0 }),
      });

      await POST(request);

      // 0 should be treated as NaN and default to 1
      expect(mockGenerateBotResponse).toHaveBeenCalledTimes(1);
    });

    it('should handle negative exchanges (defaults to 1)', async () => {
      mockSql
        .mockResolvedValueOnce([{ value: 'running' }])
        .mockResolvedValueOnce([
          { handle: 'pixel' },
          { handle: 'sage' },
        ])
        .mockResolvedValue([]);

      const request = new NextRequest('http://localhost/api/simulate', {
        method: 'POST',
        body: JSON.stringify({ exchanges: -5 }),
      });

      await POST(request);

      // Negative should be handled by Math.min(Number(-5) ?? 1, 3)
      expect(mockGenerateBotResponse).toHaveBeenCalledTimes(1);
    });

    it('should verify different bot pairs are selected for multiple exchanges', async () => {
      jest.spyOn(Math, 'random')
        .mockReturnValueOnce(0.1) // First exchange
        .mockReturnValueOnce(0.9) // Second exchange
        .mockReturnValue(0.5);

      mockSql
        .mockResolvedValueOnce([{ value: 'running' }])
        .mockResolvedValueOnce([
          { handle: 'pixel' },
          { handle: 'sage' },
          { handle: 'nova' },
        ])
        .mockResolvedValue([]);

      const request = new NextRequest('http://localhost/api/simulate', {
        method: 'POST',
        body: JSON.stringify({ exchanges: 2 }),
      });

      await POST(request);

      // Should be called twice with potentially different bot pairs
      expect(mockGenerateBotResponse).toHaveBeenCalledTimes(2);
    });
  });

  describe('PATCH endpoint edge cases', () => {
    it('should handle missing action field', async () => {
      const request = new NextRequest('http://localhost/api/simulate', {
        method: 'PATCH',
        body: JSON.stringify({}),
      });

      const response = await PATCH(request);
      const data = await response.json();

      expect(response.status).toBe(400);
      expect(data.error).toContain("action must be 'pause' or 'resume'");
    });

    it('should handle empty body', async () => {
      const request = new NextRequest('http://localhost/api/simulate', {
        method: 'PATCH',
        body: JSON.stringify({}),
      });

      const response = await PATCH(request);

      expect(response.status).toBe(400);
    });

    it('should handle case-sensitive action values', async () => {
      const request = new NextRequest('http://localhost/api/simulate', {
        method: 'PATCH',
        body: JSON.stringify({ action: 'PAUSE' }),
      });

      const response = await PATCH(request);

      // Should be case-sensitive and reject uppercase
      expect(response.status).toBe(400);
    });
  });

  describe('GET endpoint edge cases', () => {
    it('should handle world state with additional custom keys', async () => {
      mockSql.mockResolvedValueOnce([
        { key: 'status', value: 'running', updated_at: '2024-01-01T00:00:00Z' },
        { key: 'tick', value: '42', updated_at: '2024-01-01T00:00:01Z' },
        { key: 'custom_key', value: 'custom_value', updated_at: '2024-01-01T00:00:02Z' },
        { key: 'another_key', value: 'another_value', updated_at: '2024-01-01T00:00:03Z' },
      ]);

      const response = await GET();
      const data = await response.json();

      expect(data.status).toBe('running');
      expect(data.tick).toBe('42');
      expect(data.custom_key).toBe('custom_value');
      expect(data.another_key).toBe('another_value');
    });

    it('should handle world state with very long values', async () => {
      const longValue = 'A'.repeat(10000);
      mockSql.mockResolvedValueOnce([
        { key: 'status', value: longValue, updated_at: '2024-01-01T00:00:00Z' },
      ]);

      const response = await GET();
      const data = await response.json();

      expect(data.status).toBe(longValue);
    });
  });
});