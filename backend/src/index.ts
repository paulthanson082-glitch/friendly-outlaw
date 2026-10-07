import express, { Express, Request, Response, NextFunction } from 'express';
import cors from 'cors';
import { config } from './config/env.js';
import logger from './utils/logger.js';
import { errorHandler } from './middleware/errorHandler.js';
import chatRoutes from './routes/chat.js';
import authRoutes from './routes/auth.js';
import documentRoutes from './routes/documents.js';
import templateRoutes from './routes/templates.js';
import kanbanRoutes from './routes/kanban.js';
import goalRoutes from './routes/goals.js';
import { initializeDatabase } from './db/connection.js';
import { connectMongoose } from './db/mongoose.js';
import { templateService } from './services/templateService.js';

const app: Express = express();

// Initialize SQLite database
try {
  const dbPath = config.NODE_ENV === 'test' ? ':memory:' : (config.SQLITE_PATH || './data/writers_app.db');
  initializeDatabase(dbPath);
  templateService.seedDefaults();
  logger.info('Database initialized and seeded');
} catch (error) {
  logger.error('Failed to initialize database:', error);
  process.exit(1);
}

// Connect to MongoDB via Mongoose (optional)
if (config.MONGODB_URI) {
  connectMongoose(config.MONGODB_URI).catch((err) => {
    logger.warn('Mongoose connection failed — continuing without MongoDB:', err.message);
  });
}

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
app.use('/api/documents', documentRoutes);
app.use('/api/templates', templateRoutes);
app.use('/api/kanban', kanbanRoutes);
app.use('/api/writing-goals', goalRoutes);

// Root endpoint
app.get('/', (req: Request, res: Response) => {
  res.json({
    name: 'Writers App API - Jules',
    version: '1.0.0',
    description: 'AI-powered writing assistant API',
    endpoints: {
      health: '/health',
      auth: '/api/auth (register, login, profile)',
      chat: '/api/chat (sessions, messages, streaming)',
      documents: '/api/documents (CRUD, search, export)',
      templates: '/api/templates (browse, create, fill)',
      kanban: '/api/kanban (boards, tasks, workflow)',
      goals: '/api/writing-goals (create, track, update)',
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
