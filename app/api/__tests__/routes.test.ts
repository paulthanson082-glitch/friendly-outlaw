/**
 * @jest-environment node
 */
import { describe, expect, test, jest, beforeEach } from '@jest/globals';
import { NextRequest } from 'next/server';

// Mock dependencies
jest.mock('@/lib/db');
jest.mock('@/lib/ai');

const mockSql = jest.fn();
const mockGetDb = jest.fn(() => mockSql);

describe('API Routes', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockSql.mockClear();
    mockGetDb.mockClear();
  });

  describe('bots/respond route', () => {
    test('should export POST handler', () => {
      const route = require('../bots/respond/route');
      expect(typeof route.POST).toBe('function');
    });

    test('POST should be async', () => {
      const route = require('../bots/respond/route');
      expect(route.POST.constructor.name).toBe('AsyncFunction');
    });

    test('should return 400 when speaker is missing', async () => {
      const { getDb } = require('@/lib/db');
      getDb.mockReturnValue(mockSql);

      const route = require('../bots/respond/route');
      const request = new NextRequest('http://localhost/api/bots/respond', {
        method: 'POST',
        body: JSON.stringify({ listener: 'sage' }),
      });

      const response = await route.POST(request);
      const data = await response.json();

      expect(response.status).toBe(400);
      expect(data.error).toContain('speaker and listener');
    });

    test('should return 400 when listener is missing', async () => {
      const { getDb } = require('@/lib/db');
      getDb.mockReturnValue(mockSql);

      const route = require('../bots/respond/route');
      const request = new NextRequest('http://localhost/api/bots/respond', {
        method: 'POST',
        body: JSON.stringify({ speaker: 'pixel' }),
      });

      const response = await route.POST(request);
      const data = await response.json();

      expect(response.status).toBe(400);
      expect(data.error).toContain('speaker and listener');
    });

    test('should return 400 when speaker equals listener', async () => {
      const { getDb } = require('@/lib/db');
      getDb.mockReturnValue(mockSql);

      const route = require('../bots/respond/route');
      const request = new NextRequest('http://localhost/api/bots/respond', {
        method: 'POST',
        body: JSON.stringify({ speaker: 'pixel', listener: 'pixel' }),
      });

      const response = await route.POST(request);
      const data = await response.json();

      expect(response.status).toBe(400);
      expect(data.error).toContain('must be different');
    });

    test('should return 404 when speaker bot not found', async () => {
      const { getDb } = require('@/lib/db');
      getDb.mockReturnValue(mockSql);
      mockSql.mockResolvedValueOnce([]); // Empty result for speaker

      const route = require('../bots/respond/route');
      const request = new NextRequest('http://localhost/api/bots/respond', {
        method: 'POST',
        body: JSON.stringify({ speaker: 'unknown', listener: 'sage' }),
      });

      const response = await route.POST(request);
      const data = await response.json();

      expect(response.status).toBe(404);
      expect(data.error).toContain('not found');
    });

    test('should return 404 when listener bot not found', async () => {
      const { getDb } = require('@/lib/db');
      getDb.mockReturnValue(mockSql);
      mockSql
        .mockResolvedValueOnce([{ handle: 'pixel' }]) // Speaker found
        .mockResolvedValueOnce([]); // Listener not found

      const route = require('../bots/respond/route');
      const request = new NextRequest('http://localhost/api/bots/respond', {
        method: 'POST',
        body: JSON.stringify({ speaker: 'pixel', listener: 'unknown' }),
      });

      const response = await route.POST(request);
      const data = await response.json();

      expect(response.status).toBe(404);
      expect(data.error).toContain('not found');
    });

    test('should successfully create a bot response', async () => {
      const { getDb } = require('@/lib/db');
      const { generateBotResponse } = require('@/lib/ai');

      getDb.mockReturnValue(mockSql);
      generateBotResponse.mockResolvedValue('Hello there!');

      const mockMessage = {
        id: '123',
        from: 'pixel',
        to: 'sage',
        content: 'Hello there!',
        type: 'ai_response',
        timestamp: '2024-01-01T00:00:00Z',
      };

      mockSql
        .mockResolvedValueOnce([{ handle: 'pixel' }]) // Speaker found
        .mockResolvedValueOnce([{ handle: 'sage' }]) // Listener found
        .mockResolvedValueOnce([]) // Recent messages
        .mockResolvedValueOnce([]) // Memories
        .mockResolvedValueOnce([mockMessage]); // Insert message

      const route = require('../bots/respond/route');
      const request = new NextRequest('http://localhost/api/bots/respond', {
        method: 'POST',
        body: JSON.stringify({ speaker: 'pixel', listener: 'sage' }),
      });

      const response = await route.POST(request);
      const data = await response.json();

      expect(response.status).toBe(201);
      expect(data.content).toBe('Hello there!');
      expect(data.from).toBe('pixel');
      expect(data.to).toBe('sage');
    });
  });

  describe('simulate route', () => {
    test('should export POST handler', () => {
      const route = require('../simulate/route');
      expect(typeof route.POST).toBe('function');
    });

    test('should export GET handler', () => {
      const route = require('../simulate/route');
      expect(typeof route.GET).toBe('function');
    });

    test('should export PATCH handler', () => {
      const route = require('../simulate/route');
      expect(typeof route.PATCH).toBe('function');
    });

    test('handlers should be async', () => {
      const route = require('../simulate/route');
      expect(route.POST.constructor.name).toBe('AsyncFunction');
      expect(route.GET.constructor.name).toBe('AsyncFunction');
      expect(route.PATCH.constructor.name).toBe('AsyncFunction');
    });

    test('GET should return world state', async () => {
      const { getDb } = require('@/lib/db');
      getDb.mockReturnValue(mockSql);

      mockSql.mockResolvedValueOnce([
        { key: 'status', value: 'running', updated_at: '2024-01-01T00:00:00Z' },
        { key: 'tick', value: '5', updated_at: '2024-01-01T00:00:00Z' },
      ]);

      const route = require('../simulate/route');
      const response = await route.GET();
      const data = await response.json();

      expect(data.status).toBe('running');
      expect(data.tick).toBe('5');
    });

    test('POST should return 409 when simulation is paused', async () => {
      const { getDb } = require('@/lib/db');
      getDb.mockReturnValue(mockSql);

      mockSql.mockResolvedValueOnce([{ value: 'paused' }]);

      const route = require('../simulate/route');
      const request = new NextRequest('http://localhost/api/simulate', {
        method: 'POST',
        body: JSON.stringify({}),
      });

      const response = await route.POST(request);
      const data = await response.json();

      expect(response.status).toBe(409);
      expect(data.error).toContain('paused');
    });

    test('POST should return 400 when less than 2 bots exist', async () => {
      const { getDb } = require('@/lib/db');
      getDb.mockReturnValue(mockSql);

      mockSql
        .mockResolvedValueOnce([{ value: 'running' }]) // Status check
        .mockResolvedValueOnce([{ handle: 'pixel' }]); // Only 1 bot

      const route = require('../simulate/route');
      const request = new NextRequest('http://localhost/api/simulate', {
        method: 'POST',
        body: JSON.stringify({}),
      });

      const response = await route.POST(request);
      const data = await response.json();

      expect(response.status).toBe(400);
      expect(data.error).toContain('at least 2 bots');
    });

    test('PATCH should pause the simulation', async () => {
      const { getDb } = require('@/lib/db');
      getDb.mockReturnValue(mockSql);

      mockSql.mockResolvedValueOnce([]); // Update query

      const route = require('../simulate/route');
      const request = new NextRequest('http://localhost/api/simulate', {
        method: 'PATCH',
        body: JSON.stringify({ action: 'pause' }),
      });

      const response = await route.PATCH(request);
      const data = await response.json();

      expect(data.status).toBe('paused');
    });

    test('PATCH should resume the simulation', async () => {
      const { getDb } = require('@/lib/db');
      getDb.mockReturnValue(mockSql);

      mockSql.mockResolvedValueOnce([]); // Update query

      const route = require('../simulate/route');
      const request = new NextRequest('http://localhost/api/simulate', {
        method: 'PATCH',
        body: JSON.stringify({ action: 'resume' }),
      });

      const response = await route.PATCH(request);
      const data = await response.json();

      expect(data.status).toBe('running');
    });

    test('PATCH should return 400 for invalid action', async () => {
      const { getDb } = require('@/lib/db');
      getDb.mockReturnValue(mockSql);

      const route = require('../simulate/route');
      const request = new NextRequest('http://localhost/api/simulate', {
        method: 'PATCH',
        body: JSON.stringify({ action: 'invalid' }),
      });

      const response = await route.PATCH(request);
      const data = await response.json();

      expect(response.status).toBe(400);
      expect(data.error).toContain('pause');
      expect(data.error).toContain('resume');
    });
  });

  describe('town route', () => {
    test('should export GET handler', () => {
      const route = require('../town/route');
      expect(typeof route.GET).toBe('function');
    });

    test('GET should be async', () => {
      const route = require('../town/route');
      expect(route.GET.constructor.name).toBe('AsyncFunction');
    });

    test('GET should return complete town data', async () => {
      const { getDb } = require('@/lib/db');

      const mockBots = [
        { id: '1', handle: 'pixel', name: 'Pixel', description: 'An artist', created_at: '2024-01-01' },
      ];
      const mockMessages = [
        {
          id: '1',
          from: 'pixel',
          to: 'sage',
          content: 'Hello',
          type: 'message',
          timestamp: '2024-01-01',
          from_name: 'Pixel',
          to_name: 'Sage',
        },
      ];
      const mockWorldState = [
        { key: 'status', value: 'running', updated_at: '2024-01-01' },
        { key: 'tick', value: '5', updated_at: '2024-01-01' },
      ];
      const mockMemories = [
        { bot_handle: 'pixel', memory: 'I learned something', created_at: '2024-01-01' },
      ];

      // Mock SQL to return individual results for each query in Promise.all
      const mockSqlFn = jest.fn();
      mockSqlFn
        .mockResolvedValueOnce(mockBots)
        .mockResolvedValueOnce(mockMessages)
        .mockResolvedValueOnce(mockWorldState)
        .mockResolvedValueOnce(mockMemories);
      getDb.mockReturnValue(mockSqlFn);

      const route = require('../town/route');
      const response = await route.GET();
      const data = await response.json();

      expect(data).toHaveProperty('world');
      expect(data).toHaveProperty('residents');
      expect(data).toHaveProperty('feed');
    });

    test('GET should handle empty data gracefully', async () => {
      const { getDb } = require('@/lib/db');

      const mockSqlFn = jest.fn();
      mockSqlFn
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([]);
      getDb.mockReturnValue(mockSqlFn);

      const route = require('../town/route');
      const response = await route.GET();
      const data = await response.json();

      expect(data.world).toBeDefined();
      expect(data.residents).toEqual([]);
      expect(data.feed).toEqual([]);
    });

    test('GET should attach latest memory to residents', async () => {
      const { getDb } = require('@/lib/db');

      const mockBots = [
        { id: '1', handle: 'pixel', name: 'Pixel', description: 'An artist', created_at: '2024-01-01' },
      ];
      const mockMemories = [
        { bot_handle: 'pixel', memory: 'I love colors', created_at: '2024-01-01' },
      ];

      const mockSqlFn = jest.fn();
      mockSqlFn
        .mockResolvedValueOnce(mockBots)
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce(mockMemories);
      getDb.mockReturnValue(mockSqlFn);

      const route = require('../town/route');
      const response = await route.GET();
      const data = await response.json();

      expect(data.residents[0].latestMemory).toBe('I love colors');
    });
  });
});