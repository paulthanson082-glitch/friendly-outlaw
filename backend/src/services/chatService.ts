import { v4 as uuidv4 } from 'uuid';
import { aiService, AIMessage } from './aiService.js';
import logger from '../utils/logger.js';
import { NotFoundError } from '../utils/errors.js';

export interface ChatSession {
  id: string;
  userId: string;
  startedAt: Date;
  lastMessageAt: Date;
  context?: Record<string, any>;
}

export interface ChatMessage {
  id: string;
  sessionId: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
}

// In-memory storage (replace with database in phase 2)
const sessions = new Map<string, ChatSession>();
const messages = new Map<string, ChatMessage[]>();

export class ChatService {
  /**
   * Create a new chat session
   */
  createSession(userId: string, context?: Record<string, any>): ChatSession {
    const session: ChatSession = {
      id: uuidv4(),
      userId,
      startedAt: new Date(),
      lastMessageAt: new Date(),
      context,
    };
    sessions.set(session.id, session);
    messages.set(session.id, []);
    return session;
  }

  /**
   * Get session by ID
   */
  getSession(sessionId: string): ChatSession | undefined {
    return sessions.get(sessionId);
  }

  /**
   * Get all sessions for a user
   */
  getUserSessions(userId: string): ChatSession[] {
    return Array.from(sessions.values()).filter((s) => s.userId === userId);
  }

  /**
   * Add a message to session history
   */
  addMessage(
    sessionId: string,
    role: 'user' | 'assistant',
    content: string
  ): ChatMessage {
    const session = sessions.get(sessionId);
    if (!session) {
      throw new NotFoundError('Chat session');
    }

    const message: ChatMessage = {
      id: uuidv4(),
      sessionId,
      role,
      content,
      timestamp: new Date(),
    };

    if (!messages.has(sessionId)) {
      messages.set(sessionId, []);
    }
    messages.get(sessionId)!.push(message);

    // Update last message time
    session.lastMessageAt = new Date();

    return message;
  }

  /**
   * Get chat history for a session
   */
  getHistory(sessionId: string): ChatMessage[] {
    return messages.get(sessionId) || [];
  }

  /**
   * Convert history to AI message format
   */
  private historyToAIMessages(sessionId: string): AIMessage[] {
    const history = this.getHistory(sessionId);
    return history.map((m) => ({
      role: m.role,
      content: m.content,
    }));
  }

  /**
   * Stream a message to Jules
   */
  async *sendMessage(
    sessionId: string,
    userMessage: string,
    systemPrompt?: string
  ) {
    const session = this.getSession(sessionId);
    if (!session) {
      throw new NotFoundError('Chat session');
    }

    // Add user message to history
    this.addMessage(sessionId, 'user', userMessage);

    // Get conversation history
    const history = this.historyToAIMessages(sessionId);
    // Remove the last message (user's current message) to avoid duplication
    history.pop();

    let assistantResponse = '';

    try {
      // Stream response from Claude
      for await (const chunk of aiService.streamMessage(
        userMessage,
        history,
        systemPrompt
      )) {
        if (chunk.type === 'text') {
          assistantResponse += chunk.content;
        }
        yield chunk;
      }

      // Save assistant response
      if (assistantResponse) {
        this.addMessage(sessionId, 'assistant', assistantResponse);
      }
    } catch (error) {
      logger.error('Chat stream error:', error);
      throw error;
    }
  }

  /**
   * Delete a session and its messages
   */
  deleteSession(sessionId: string): boolean {
    messages.delete(sessionId);
    return sessions.delete(sessionId);
  }

  /**
   * Clear message history for a session
   */
  clearHistory(sessionId: string): boolean {
    const session = sessions.get(sessionId);
    if (!session) return false;
    messages.set(sessionId, []);
    return true;
  }

  /**
   * Get session statistics
   */
  getSessionStats(sessionId: string): { messageCount: number; duration: number } {
    const session = this.getSession(sessionId);
    if (!session) {
      throw new NotFoundError('Chat session');
    }

    const history = this.getHistory(sessionId);
    const duration = session.lastMessageAt.getTime() - session.startedAt.getTime();

    return {
      messageCount: history.length,
      duration, // milliseconds
    };
  }
}

export const chatService = new ChatService();
