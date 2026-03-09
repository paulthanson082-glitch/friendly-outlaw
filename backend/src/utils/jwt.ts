import jwt from 'jsonwebtoken';
import { config } from '../config/env.js';

export interface JWTPayload {
  userId: string;
  email: string;
  iat?: number;
  exp?: number;
}

export const generateToken = (payload: Omit<JWTPayload, 'iat' | 'exp'>): string => {
  return jwt.sign(payload as any, config.JWT_SECRET as any, {
    expiresIn: config.JWT_EXPIRES_IN,
  } as any);
};

export const verifyToken = (token: string): JWTPayload => {
  try {
    return jwt.verify(token, config.JWT_SECRET as any) as JWTPayload;
  } catch (error) {
    throw new Error('Invalid or expired token');
  }
};

export const extractTokenFromHeader = (authHeader?: string): string | null => {
  if (!authHeader) return null;
  const parts = authHeader.split(' ');
  if (parts.length !== 2 || parts[0] !== 'Bearer') return null;
  return parts[1];
};
