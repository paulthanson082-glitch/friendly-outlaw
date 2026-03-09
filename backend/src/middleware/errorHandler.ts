import { Request, Response, NextFunction } from 'express';
import { AppError } from '../utils/errors.js';
import logger from '../utils/logger.js';
import { config } from '../config/env.js';

export const errorHandler = (
  error: Error | AppError,
  req: Request,
  res: Response,
  next: NextFunction
) => {
  if (error instanceof AppError) {
    if (!error.isOperational) {
      logger.error('Unhandled error:', error);
    }
    return res.status(error.statusCode).json({
      error: error.message,
      ...(config.NODE_ENV === 'development' && { stack: error.stack }),
    });
  }

  logger.error('Unexpected error:', error);
  res.status(500).json({
    error: 'Internal server error',
    ...(config.NODE_ENV === 'development' && {
      details: error instanceof Error ? error.message : String(error),
      stack: error instanceof Error ? error.stack : undefined,
    }),
  });
};

export const asyncHandler = (fn: Function) => {
  return (req: Request, res: Response, next: NextFunction) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};
