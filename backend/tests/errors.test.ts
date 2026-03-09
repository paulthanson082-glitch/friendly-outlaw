import {
  AppError,
  ValidationError,
  UnauthorizedError,
  ForbiddenError,
  NotFoundError,
  ConflictError,
  InternalServerError,
  AIServiceError,
} from '../src/utils/errors';

describe('AppError', () => {
  it('creates error with statusCode and message', () => {
    const error = new AppError(400, 'Bad request');
    expect(error.statusCode).toBe(400);
    expect(error.message).toBe('Bad request');
    expect(error.isOperational).toBe(true);
  });

  it('allows non-operational flag', () => {
    const error = new AppError(500, 'Server error', false);
    expect(error.isOperational).toBe(false);
  });

  it('is instanceof Error', () => {
    const error = new AppError(400, 'test');
    expect(error).toBeInstanceOf(Error);
  });
});

describe('ValidationError', () => {
  it('has statusCode 400', () => {
    const error = new ValidationError('Invalid input');
    expect(error.statusCode).toBe(400);
    expect(error.message).toBe('Invalid input');
  });

  it('is instanceof AppError', () => {
    const error = new ValidationError('test');
    expect(error).toBeInstanceOf(AppError);
  });
});

describe('UnauthorizedError', () => {
  it('has statusCode 401', () => {
    const error = new UnauthorizedError();
    expect(error.statusCode).toBe(401);
    expect(error.message).toBe('Unauthorized');
  });

  it('accepts custom message', () => {
    const error = new UnauthorizedError('Token expired');
    expect(error.message).toBe('Token expired');
  });
});

describe('ForbiddenError', () => {
  it('has statusCode 403', () => {
    const error = new ForbiddenError();
    expect(error.statusCode).toBe(403);
    expect(error.message).toBe('Forbidden');
  });
});

describe('NotFoundError', () => {
  it('has statusCode 404 and includes resource name', () => {
    const error = new NotFoundError('Document');
    expect(error.statusCode).toBe(404);
    expect(error.message).toBe('Document not found');
  });
});

describe('ConflictError', () => {
  it('has statusCode 409', () => {
    const error = new ConflictError('Email already exists');
    expect(error.statusCode).toBe(409);
    expect(error.message).toBe('Email already exists');
  });
});

describe('InternalServerError', () => {
  it('has statusCode 500 and is not operational', () => {
    const error = new InternalServerError();
    expect(error.statusCode).toBe(500);
    expect(error.isOperational).toBe(false);
    expect(error.message).toBe('Internal server error');
  });

  it('accepts custom message', () => {
    const error = new InternalServerError('Database connection failed');
    expect(error.message).toBe('Database connection failed');
  });
});

describe('AIServiceError', () => {
  it('has statusCode 500 and stores originalError', () => {
    const original = new Error('API rate limit exceeded');
    const error = new AIServiceError(original);
    expect(error.statusCode).toBe(500);
    expect(error.originalError).toBe(original);
    expect(error.message).toBe('AI service error');
  });

  it('accepts custom message', () => {
    const original = new Error('network error');
    const error = new AIServiceError(original, 'Claude API unavailable');
    expect(error.message).toBe('Claude API unavailable');
  });
});
