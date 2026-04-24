import mongoose from 'mongoose';
import logger from '../utils/logger.js';

let isConnected = false;

export const connectMongoose = async (uri: string): Promise<void> => {
  if (isConnected) return;

  mongoose.set('strictQuery', false);

  mongoose.connection.on('connected', () => {
    logger.info('MongoDB connected via Mongoose');
  });

  mongoose.connection.on('error', (err) => {
    logger.error('MongoDB connection error:', err);
  });

  mongoose.connection.on('disconnected', () => {
    logger.warn('MongoDB disconnected');
    isConnected = false;
  });

  await mongoose.connect(uri, {
    serverSelectionTimeoutMS: 5000,
    socketTimeoutMS: 45000,
  });

  isConnected = true;
};

export const disconnectMongoose = async (): Promise<void> => {
  if (!isConnected) return;
  await mongoose.disconnect();
  isConnected = false;
};

export const isMongooseConnected = (): boolean => isConnected;

export default mongoose;
