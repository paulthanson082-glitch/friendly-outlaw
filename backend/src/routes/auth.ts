import { Router, Request, Response } from 'express';
import { hash, compare } from 'bcryptjs';
import { generateToken, JWTPayload } from '../utils/jwt.js';
import { authMiddleware } from '../middleware/auth.js';
import { asyncHandler } from '../middleware/errorHandler.js';
import { ValidationError, UnauthorizedError, ConflictError } from '../utils/errors.js';
import { v4 as uuidv4 } from 'uuid';

const router = Router();

// In-memory user storage (replace with database in phase 2)
interface User {
  id: string;
  email: string;
  passwordHash: string;
  displayName?: string;
}

const users = new Map<string, User>();
const usersByEmail = new Map<string, User>();

/**
 * POST /api/auth/register
 * Register a new user
 */
router.post(
  '/register',
  asyncHandler(async (req: Request, res: Response) => {
    const { email, password, displayName } = req.body;

    // Validate input
    if (!email || !password) {
      throw new ValidationError('email and password are required');
    }

    if (typeof email !== 'string' || !email.includes('@')) {
      throw new ValidationError('email must be a valid email address');
    }

    if (typeof password !== 'string' || password.length < 8) {
      throw new ValidationError('password must be at least 8 characters');
    }

    // Check if user exists
    if (usersByEmail.has(email)) {
      throw new ConflictError('User with this email already exists');
    }

    // Hash password
    const passwordHash = await hash(password, 10);

    // Create user
    const user: User = {
      id: uuidv4(),
      email,
      passwordHash,
      displayName: displayName || email.split('@')[0],
    };

    users.set(user.id, user);
    usersByEmail.set(email, user);

    // Generate token
    const token = generateToken({
      userId: user.id,
      email: user.email,
    });

    res.status(201).json({
      token,
      user: {
        id: user.id,
        email: user.email,
        displayName: user.displayName,
      },
    });
  })
);

/**
 * POST /api/auth/login
 * Login user
 */
router.post(
  '/login',
  asyncHandler(async (req: Request, res: Response) => {
    const { email, password } = req.body;

    // Validate input
    if (!email || !password) {
      throw new ValidationError('email and password are required');
    }

    // Find user
    const user = usersByEmail.get(email);
    if (!user) {
      throw new UnauthorizedError('Invalid email or password');
    }

    // Verify password
    const isValid = await compare(password, user.passwordHash);
    if (!isValid) {
      throw new UnauthorizedError('Invalid email or password');
    }

    // Generate token
    const token = generateToken({
      userId: user.id,
      email: user.email,
    });

    res.json({
      token,
      user: {
        id: user.id,
        email: user.email,
        displayName: user.displayName,
      },
    });
  })
);

/**
 * GET /api/auth/me
 * Get current user
 */
router.get(
  '/me',
  authMiddleware,
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!.userId;
    const user = users.get(userId);

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({
      id: user.id,
      email: user.email,
      displayName: user.displayName,
    });
  })
);

/**
 * PUT /api/auth/profile
 * Update user profile
 */
router.put(
  '/profile',
  authMiddleware,
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!.userId;
    const { displayName } = req.body;

    const user = users.get(userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    if (displayName) {
      user.displayName = displayName;
    }

    res.json({
      id: user.id,
      email: user.email,
      displayName: user.displayName,
    });
  })
);

export default router;
