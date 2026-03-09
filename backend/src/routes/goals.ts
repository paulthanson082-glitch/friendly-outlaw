import { Router, Request, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { getDatabase } from '../db/connection.js';
import { authMiddleware } from '../middleware/auth.js';
import { asyncHandler } from '../middleware/errorHandler.js';
import { ValidationError, NotFoundError } from '../utils/errors.js';

const router = Router();

router.use(authMiddleware);

interface WritingGoal {
  id: string;
  userId: string;
  title: string;
  description?: string;
  goalType: string;
  unit: string;
  targetValue: number;
  currentValue: number;
  deadline?: string;
  achievedAt?: string;
  createdAt: string;
  metadata?: Record<string, any>;
}

/**
 * POST /api/writing-goals
 * Create a new writing goal
 */
router.post(
  '/',
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!.userId;
    const { title, description, goalType, unit, targetValue, deadline } = req.body;

    if (!title || !goalType || !unit || !targetValue) {
      throw new ValidationError('title, goalType, unit, and targetValue are required');
    }

    const db = getDatabase();
    const id = uuidv4();
    const now = new Date().toISOString();

    const stmt = db.prepare(`
      INSERT INTO writing_goals (id, user_id, title, description, goal_type, unit, target_value, deadline, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);

    stmt.run(id, userId, title, description || '', goalType, unit, targetValue, deadline || null, now);

    const goal = getGoal(id);
    res.status(201).json(goal);
  })
);

/**
 * GET /api/writing-goals
 * Get all goals for the user
 */
router.get(
  '/',
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!.userId;
    const db = getDatabase();

    const stmt = db.prepare(`
      SELECT * FROM writing_goals
      WHERE user_id = ?
      ORDER BY created_at DESC
    `);

    const rows = stmt.all(userId) as any[];
    const goals = rows.map(parseGoal);

    res.json(goals);
  })
);

/**
 * GET /api/writing-goals/:id
 * Get a specific goal
 */
router.get(
  '/:id',
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!.userId;
    const { id } = req.params;

    const goal = getGoal(id);
    if (!goal || goal.userId !== userId) {
      throw new NotFoundError('Goal');
    }

    res.json(goal);
  })
);

/**
 * PUT /api/writing-goals/:id
 * Update a goal
 */
router.put(
  '/:id',
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!.userId;
    const { id } = req.params;
    const { title, description, targetValue, deadline } = req.body;

    const goal = getGoal(id);
    if (!goal || goal.userId !== userId) {
      throw new NotFoundError('Goal');
    }

    const db = getDatabase();
    const stmt = db.prepare(`
      UPDATE writing_goals
      SET title = ?, description = ?, target_value = ?, deadline = ?
      WHERE id = ?
    `);

    stmt.run(title ?? goal.title, description ?? goal.description, targetValue ?? goal.targetValue, deadline ?? goal.deadline, id);

    res.json(getGoal(id));
  })
);

/**
 * POST /api/writing-goals/:id/progress
 * Update goal progress
 */
router.post(
  '/:id/progress',
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!.userId;
    const { id } = req.params;
    const { currentValue } = req.body;

    if (typeof currentValue !== 'number') {
      throw new ValidationError('currentValue must be a number');
    }

    const goal = getGoal(id);
    if (!goal || goal.userId !== userId) {
      throw new NotFoundError('Goal');
    }

    const db = getDatabase();
    const now = new Date().toISOString();
    const achievedAt = currentValue >= goal.targetValue ? now : null;

    const stmt = db.prepare(`
      UPDATE writing_goals
      SET current_value = ?, achieved_at = ?
      WHERE id = ?
    `);

    stmt.run(currentValue, achievedAt, id);

    res.json(getGoal(id));
  })
);

/**
 * DELETE /api/writing-goals/:id
 * Delete a goal
 */
router.delete(
  '/:id',
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!.userId;
    const { id } = req.params;

    const goal = getGoal(id);
    if (!goal || goal.userId !== userId) {
      throw new NotFoundError('Goal');
    }

    const db = getDatabase();
    const stmt = db.prepare('DELETE FROM writing_goals WHERE id = ?');
    stmt.run(id);

    res.status(204).send();
  })
);

/**
 * GET /api/writing-goals/:id/stats
 * Get goal statistics
 */
router.get(
  '/:id/stats',
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!.userId;
    const { id } = req.params;

    const goal = getGoal(id);
    if (!goal || goal.userId !== userId) {
      throw new NotFoundError('Goal');
    }

    const progress = (goal.currentValue / goal.targetValue) * 100;
    const isAchieved = goal.achievedAt !== null && goal.achievedAt !== undefined;

    res.json({
      ...goal,
      progressPercentage: Math.min(100, Math.round(progress)),
      isAchieved,
      remaining: Math.max(0, goal.targetValue - goal.currentValue),
    });
  })
);

// Helper functions
function getGoal(id: string): WritingGoal | null {
  const db = getDatabase();
  const stmt = db.prepare('SELECT * FROM writing_goals WHERE id = ?');
  const row = stmt.get(id) as any;
  return row ? parseGoal(row) : null;
}

function parseGoal(row: any): WritingGoal {
  return {
    id: row.id,
    userId: row.user_id,
    title: row.title,
    description: row.description,
    goalType: row.goal_type,
    unit: row.unit,
    targetValue: row.target_value,
    currentValue: row.current_value,
    deadline: row.deadline,
    achievedAt: row.achieved_at,
    createdAt: row.created_at,
    metadata: row.metadata ? JSON.parse(row.metadata) : undefined,
  };
}

export default router;
