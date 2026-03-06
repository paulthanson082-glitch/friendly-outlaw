import express, { Express, Request, Response, NextFunction } from 'express';
import cors from 'cors';
import { config } from './config/env.js';
import logger from './utils/logger.js';
import { errorHandler } from './middleware/errorHandler.js';
import chatRoutes from './routes/chat.js';
import authRoutes from './routes/auth.js';

const app: Express = express();

// Middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));

// CORS
const corsOrigins = config.CORS_ORIGIN.split(',').map((origin) => origin.trim());
app.use(
  cors({
    origin: corsOrigins,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  })
);

// Request logging
app.use((req: Request, res: Response, next: NextFunction) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    logger.info(`${req.method} ${req.path}`, {
      status: res.statusCode,
      duration: `${duration}ms`,
    });
  });
  next();
});

// Health check
app.get('/health', (req: Request, res: Response) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/chat', chatRoutes);

// Root endpoint
app.get('/', (req: Request, res: Response) => {
  res.json({
    name: 'Writers App API',
    version: '1.0.0',
    description: 'Jules AI-powered writing assistant API',
    endpoints: {
      health: '/health',
      auth: '/api/auth',
      chat: '/api/chat',
    },
  });
});

// 404 handler
app.use((req: Request, res: Response) => {
  res.status(404).json({
    error: 'Not found',
    path: req.path,
    method: req.method,
  });
});

// Error handler (must be last)
app.use(errorHandler);

// Start server
const PORT = config.PORT;
app.listen(PORT, () => {
  logger.info(`Server running on http://localhost:${PORT}`);
  logger.info(`Environment: ${config.NODE_ENV}`);
});

export default app;
