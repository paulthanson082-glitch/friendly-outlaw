import { Router, Request, Response } from 'express';
import { chatService } from '../services/chatService.js';
import { authMiddleware } from '../middleware/auth.js';
import { asyncHandler } from '../middleware/errorHandler.js';
import { ValidationError } from '../utils/errors.js';
import logger from '../utils/logger.js';

const router = Router();

// Require authentication for all chat routes
router.use(authMiddleware);

/**
 * POST /api/chat/sessions
 * Create a new chat session
 */
router.post(
  '/sessions',
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!.userId;
    const { context } = req.body;

    const session = chatService.createSession(userId, context);
    res.status(201).json(session);
  })
);

/**
 * GET /api/chat/sessions
 * Get all sessions for the current user
 */
router.get(
  '/sessions',
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!.userId;
    const sessions = chatService.getUserSessions(userId);
    res.json(sessions);
  })
);

/**
 * GET /api/chat/sessions/:sessionId
 * Get a specific chat session
 */
router.get(
  '/sessions/:sessionId',
  asyncHandler(async (req: Request, res: Response) => {
    const { sessionId } = req.params;
    const session = chatService.getSession(sessionId);

    if (!session) {
      return res.status(404).json({ error: 'Session not found' });
    }

    // Verify ownership
    if (session.userId !== req.user!.userId) {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    res.json(session);
  })
);

/**
 * GET /api/chat/sessions/:sessionId/history
 * Get conversation history for a session
 */
router.get(
  '/sessions/:sessionId/history',
  asyncHandler(async (req: Request, res: Response) => {
    const { sessionId } = req.params;
    const session = chatService.getSession(sessionId);

    if (!session) {
      return res.status(404).json({ error: 'Session not found' });
    }

    // Verify ownership
    if (session.userId !== req.user!.userId) {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    const history = chatService.getHistory(sessionId);
    res.json(history);
  })
);

/**
 * POST /api/chat/send
 * Send a message to Jules (Server-Sent Events stream)
 */
router.post(
  '/send',
  asyncHandler(async (req: Request, res: Response) => {
    const { sessionId, message, systemPrompt } = req.body;
    const userId = req.user!.userId;

    // Validate input
    if (!sessionId || !message) {
      throw new ValidationError('sessionId and message are required');
    }

    if (typeof message !== 'string' || message.trim().length === 0) {
      throw new ValidationError('message must be a non-empty string');
    }

    // Verify session ownership
    const session = chatService.getSession(sessionId);
    if (!session) {
      return res.status(404).json({ error: 'Session not found' });
    }

    if (session.userId !== userId) {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    // Set up SSE headers
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    res.setHeader('Access-Control-Allow-Origin', '*');

    try {
      // Stream the response
      for await (const chunk of chatService.sendMessage(
        sessionId,
        message,
        systemPrompt
      )) {
        if (chunk.type === 'text') {
          res.write(`data: ${JSON.stringify({ type: 'text', content: chunk.content })}\n\n`);
        } else if (chunk.type === 'error') {
          res.write(`data: ${JSON.stringify({ type: 'error', content: chunk.content })}\n\n`);
        } else if (chunk.type === 'stop') {
          res.write(`data: ${JSON.stringify({ type: 'stop', content: '' })}\n\n`);
        }
      }

      res.write('data: [DONE]\n\n');
      res.end();
    } catch (error) {
      logger.error('Chat send error:', error);
      res.write(
        `data: ${JSON.stringify({
          type: 'error',
          content: 'An error occurred while processing your message',
        })}\n\n`
      );
      res.end();
    }
  })
);

/**
 * POST /api/chat/sessions/:sessionId/clear
 * Clear message history for a session
 */
router.post(
  '/sessions/:sessionId/clear',
  asyncHandler(async (req: Request, res: Response) => {
    const { sessionId } = req.params;
    const session = chatService.getSession(sessionId);

    if (!session) {
      return res.status(404).json({ error: 'Session not found' });
    }

    if (session.userId !== req.user!.userId) {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    chatService.clearHistory(sessionId);
    res.json({ message: 'History cleared' });
  })
);

/**
 * DELETE /api/chat/sessions/:sessionId
 * Delete a chat session
 */
router.delete(
  '/sessions/:sessionId',
  asyncHandler(async (req: Request, res: Response) => {
    const { sessionId } = req.params;
    const session = chatService.getSession(sessionId);

    if (!session) {
      return res.status(404).json({ error: 'Session not found' });
    }

    if (session.userId !== req.user!.userId) {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    chatService.deleteSession(sessionId);
    res.status(204).send();
  })
);

export default router;
