import { Request, Response, NextFunction } from 'express';
import { extractTokenFromHeader, verifyToken, JWTPayload } from '../utils/jwt.js';
import { UnauthorizedError } from '../utils/errors.js';

declare global {
  namespace Express {
    interface Request {
      user?: JWTPayload;
    }
  }
}

export const authMiddleware = (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const token = extractTokenFromHeader(req.headers.authorization);
    if (!token) {
      throw new UnauthorizedError('Missing authorization token');
    }

    const payload = verifyToken(token);
    req.user = payload;
    next();
  } catch (error) {
    if (error instanceof UnauthorizedError) {
      res.status(error.statusCode).json({ error: error.message });
    } else {
      res.status(401).json({ error: 'Invalid token' });
    }
  }
};

export const optionalAuthMiddleware = (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const token = extractTokenFromHeader(req.headers.authorization);
    if (token) {
      const payload = verifyToken(token);
      req.user = payload;
    }
  } catch (error) {
    // Silently skip auth errors for optional auth
  }
  next();
};
