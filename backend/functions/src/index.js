const functions = require('firebase-functions');
const express = require('express');
const cors = require('cors');
require('dotenv').config();

const authRouter = require('./auth');
const jokesRouter = require('./jokes');
const chatRouter = require('./chat');
const { errorHandler, authMiddleware } = require('./middleware');

const app = express();

// Middleware
app.use(cors({ origin: true }));
app.use(express.json());

// Routes
app.use('/auth', authRouter);
app.use('/jokes', authMiddleware, jokesRouter);
app.use('/chat', authMiddleware, chatRouter);

// Error handler
app.use(errorHandler);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// Export Cloud Function
exports.api = functions.https.onRequest(app);
