// Mock aiService before importing chatService to avoid Anthropic SDK initialization
jest.mock('../src/services/aiService', () => ({
  aiService: {
    streamMessage: jest.fn(),
  },
  AIMessage: {},
}));

import { ChatService } from '../src/services/chatService';
import { NotFoundError } from '../src/utils/errors';

describe('ChatService', () => {
  let service: ChatService;

  beforeEach(() => {
    service = new ChatService();
  });

  describe('createSession', () => {
    it('creates a session with a unique id', () => {
      const session = service.createSession('user-1');
      expect(session.id).toBeDefined();
      expect(session.userId).toBe('user-1');
      expect(session.startedAt).toBeInstanceOf(Date);
      expect(session.lastMessageAt).toBeInstanceOf(Date);
    });

    it('creates sessions with unique ids', () => {
      const s1 = service.createSession('user-1');
      const s2 = service.createSession('user-1');
      expect(s1.id).not.toBe(s2.id);
    });

    it('stores context when provided', () => {
      const context = { documentId: 'doc-123', genre: 'noir' };
      const session = service.createSession('user-1', context);
      expect(session.context).toEqual(context);
    });
  });

  describe('getSession', () => {
    it('returns an existing session', () => {
      const created = service.createSession('user-1');
      const found = service.getSession(created.id);
      expect(found).toBeDefined();
      expect(found!.id).toBe(created.id);
    });

    it('returns undefined for unknown session', () => {
      expect(service.getSession('non-existent')).toBeUndefined();
    });
  });

  describe('getUserSessions', () => {
    it('returns only sessions for the given user', () => {
      service.createSession('user-1');
      service.createSession('user-1');
      service.createSession('user-2');

      const user1Sessions = service.getUserSessions('user-1');
      expect(user1Sessions).toHaveLength(2);
      user1Sessions.forEach((s) => expect(s.userId).toBe('user-1'));
    });

    it('returns empty array when user has no sessions', () => {
      expect(service.getUserSessions('unknown-user')).toHaveLength(0);
    });
  });

  describe('addMessage', () => {
    it('adds a message to the session', () => {
      const session = service.createSession('user-1');
      const message = service.addMessage(session.id, 'user', 'Hello, Jules!');

      expect(message.id).toBeDefined();
      expect(message.sessionId).toBe(session.id);
      expect(message.role).toBe('user');
      expect(message.content).toBe('Hello, Jules!');
      expect(message.timestamp).toBeInstanceOf(Date);
    });

    it('throws NotFoundError for unknown session', () => {
      expect(() => service.addMessage('bad-id', 'user', 'hello')).toThrow(NotFoundError);
    });

    it('updates lastMessageAt on the session', () => {
      const session = service.createSession('user-1');
      const before = session.lastMessageAt;
      service.addMessage(session.id, 'user', 'test');
      const updated = service.getSession(session.id)!;
      expect(updated.lastMessageAt.getTime()).toBeGreaterThanOrEqual(before.getTime());
    });
  });

  describe('getHistory', () => {
    it('returns empty array for new session', () => {
      const session = service.createSession('user-1');
      expect(service.getHistory(session.id)).toHaveLength(0);
    });

    it('returns all messages in order', () => {
      const session = service.createSession('user-1');
      service.addMessage(session.id, 'user', 'First');
      service.addMessage(session.id, 'assistant', 'Reply');
      service.addMessage(session.id, 'user', 'Second');

      const history = service.getHistory(session.id);
      expect(history).toHaveLength(3);
      expect(history[0].content).toBe('First');
      expect(history[1].content).toBe('Reply');
      expect(history[2].content).toBe('Second');
    });
  });

  describe('clearHistory', () => {
    it('removes all messages from session', () => {
      const session = service.createSession('user-1');
      service.addMessage(session.id, 'user', 'Hello');
      service.addMessage(session.id, 'assistant', 'Hi there');

      const cleared = service.clearHistory(session.id);
      expect(cleared).toBe(true);
      expect(service.getHistory(session.id)).toHaveLength(0);
    });

    it('returns false for unknown session', () => {
      expect(service.clearHistory('non-existent')).toBe(false);
    });
  });

  describe('deleteSession', () => {
    it('removes session and its messages', () => {
      const session = service.createSession('user-1');
      service.addMessage(session.id, 'user', 'Hello');

      const deleted = service.deleteSession(session.id);
      expect(deleted).toBe(true);
      expect(service.getSession(session.id)).toBeUndefined();
      expect(service.getHistory(session.id)).toHaveLength(0);
    });

    it('returns false when session does not exist', () => {
      expect(service.deleteSession('non-existent')).toBe(false);
    });
  });

  describe('getSessionStats', () => {
    it('returns message count and duration', () => {
      const session = service.createSession('user-1');
      service.addMessage(session.id, 'user', 'Hello');
      service.addMessage(session.id, 'assistant', 'Hi');

      const stats = service.getSessionStats(session.id);
      expect(stats.messageCount).toBe(2);
      expect(stats.duration).toBeGreaterThanOrEqual(0);
    });

    it('throws NotFoundError for unknown session', () => {
      expect(() => service.getSessionStats('bad-id')).toThrow(NotFoundError);
    });

    it('returns zero messages for empty session', () => {
      const session = service.createSession('user-1');
      const stats = service.getSessionStats(session.id);
      expect(stats.messageCount).toBe(0);
    });
  });
});
