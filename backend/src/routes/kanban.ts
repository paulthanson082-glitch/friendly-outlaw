import { Router, Request, Response } from 'express';
import { kanbanService } from '../services/kanbanService.js';
import { authMiddleware } from '../middleware/auth.js';
import { asyncHandler } from '../middleware/errorHandler.js';
import { ValidationError, NotFoundError } from '../utils/errors.js';

const router = Router();

// Require authentication
router.use(authMiddleware);

/**
 * POST /api/kanban/boards
 * Create a new Kanban board
 */
router.post(
  '/boards',
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!.userId;
    const { name, description } = req.body;

    if (!name) {
      throw new ValidationError('name is required');
    }

    const board = kanbanService.createBoard(userId, name, description);
    res.status(201).json(board);
  })
);

/**
 * GET /api/kanban/boards
 * Get all boards for the user
 */
router.get(
  '/boards',
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!.userId;
    const boards = kanbanService.getUserBoards(userId);
    res.json(boards);
  })
);

/**
 * GET /api/kanban/boards/:boardId
 * Get a board with all its tasks
 */
router.get(
  '/boards/:boardId',
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!.userId;
    const { boardId } = req.params;

    const board = kanbanService.getBoard(boardId);
    if (!board || board.userId !== userId) {
      throw new NotFoundError('Board');
    }

    const tasks = kanbanService.getTasks(boardId);
    res.json({ ...board, tasks });
  })
);

/**
 * DELETE /api/kanban/boards/:boardId
 * Delete a board (cascade deletes tasks)
 */
router.delete(
  '/boards/:boardId',
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!.userId;
    const { boardId } = req.params;

    const board = kanbanService.getBoard(boardId);
    if (!board || board.userId !== userId) {
      throw new NotFoundError('Board');
    }

    kanbanService.deleteBoard(boardId);
    res.status(204).send();
  })
);

/**
 * POST /api/kanban/tasks
 * Create a new task
 */
router.post(
  '/tasks',
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!.userId;
    const { boardId, title, description, column } = req.body;

    if (!boardId || !title) {
      throw new ValidationError('boardId and title are required');
    }

    // Verify board ownership
    const board = kanbanService.getBoard(boardId);
    if (!board || board.userId !== userId) {
      throw new NotFoundError('Board');
    }

    const task = kanbanService.createTask(boardId, title, description, column);
    res.status(201).json(task);
  })
);

/**
 * GET /api/kanban/tasks/:taskId
 * Get a specific task
 */
router.get(
  '/tasks/:taskId',
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!.userId;
    const { taskId } = req.params;

    const task = kanbanService.getTask(taskId);
    if (!task) {
      throw new NotFoundError('Task');
    }

    // Verify board ownership
    const board = kanbanService.getBoard(task.boardId);
    if (!board || board.userId !== userId) {
      throw new NotFoundError('Task');
    }

    res.json(task);
  })
);

/**
 * PUT /api/kanban/tasks/:taskId
 * Update a task
 */
router.put(
  '/tasks/:taskId',
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!.userId;
    const { taskId } = req.params;
    const { title, description } = req.body;

    const task = kanbanService.getTask(taskId);
    if (!task) {
      throw new NotFoundError('Task');
    }

    const board = kanbanService.getBoard(task.boardId);
    if (!board || board.userId !== userId) {
      throw new NotFoundError('Task');
    }

    const updated = kanbanService.updateTask(taskId, { title, description } as any);
    res.json(updated);
  })
);

/**
 * POST /api/kanban/tasks/:taskId/move
 * Move a task to a different column
 */
router.post(
  '/tasks/:taskId/move',
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!.userId;
    const { taskId } = req.params;
    const { column } = req.body;

    if (!column) {
      throw new ValidationError('column is required');
    }

    const task = kanbanService.getTask(taskId);
    if (!task) {
      throw new NotFoundError('Task');
    }

    const board = kanbanService.getBoard(task.boardId);
    if (!board || board.userId !== userId) {
      throw new NotFoundError('Task');
    }

    const updated = kanbanService.moveTask(taskId, column);
    res.json(updated);
  })
);

/**
 * DELETE /api/kanban/tasks/:taskId
 * Delete a task
 */
router.delete(
  '/tasks/:taskId',
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!.userId;
    const { taskId } = req.params;

    const task = kanbanService.getTask(taskId);
    if (!task) {
      throw new NotFoundError('Task');
    }

    const board = kanbanService.getBoard(task.boardId);
    if (!board || board.userId !== userId) {
      throw new NotFoundError('Task');
    }

    kanbanService.deleteTask(taskId);
    res.status(204).send();
  })
);

/**
 * GET /api/kanban/tasks/search
 * Search tasks by query
 */
router.get(
  '/tasks/search',
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!.userId;
    const { q } = req.query;

    if (!q) {
      throw new ValidationError('q (query) parameter is required');
    }

    // Note: Simplified search - in production, would use full-text indexing
    const allBoards = kanbanService.getUserBoards(userId);
    const results = allBoards
      .flatMap((board) => kanbanService.getTasks(board.id))
      .filter((task) => task.title.toLowerCase().includes((q as string).toLowerCase()) ||
        (task.description?.toLowerCase().includes((q as string).toLowerCase())));

    res.json(results);
  })
);

export default router;
