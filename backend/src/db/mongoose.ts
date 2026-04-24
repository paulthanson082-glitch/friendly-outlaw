import mongoose from 'mongoose';
import logger from '../utils/logger.js';

let connectionPromise: Promise<void> | null = null;

export const connectMongoose = async (uri: string): Promise<void> => {
  if (mongoose.connection.readyState === 1) return;

  if (!connectionPromise) {
    connectionPromise = (async () => {
      mongoose.set('strictQuery', false);

      mongoose.connection.on('connected', () => {
        logger.info('MongoDB connected via Mongoose');
      });

      mongoose.connection.on('error', (err) => {
        logger.error('MongoDB connection error:', err);
      });

      mongoose.connection.on('disconnected', () => {
        logger.warn('MongoDB disconnected');
        connectionPromise = null;
      });

      await mongoose.connect(uri, {
        serverSelectionTimeoutMS: 5000,
        socketTimeoutMS: 45000,
      });
    })();
  }

  return connectionPromise;
};

export const disconnectMongoose = async (): Promise<void> => {
  if (mongoose.connection.readyState === 0) return;
  await mongoose.disconnect();
  connectionPromise = null;
};

export const isMongooseConnected = (): boolean =>
  mongoose.connection.readyState === 1;

export default mongoose;
