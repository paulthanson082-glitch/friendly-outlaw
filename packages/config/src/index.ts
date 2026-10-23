/**
 * Shared configuration for the friendly-outlaw monorepo
 */

import { z } from 'zod';

// Environment validation schema
export const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  ANTHROPIC_API_KEY: z.string().optional(),
  DATABASE_URL: z.string().optional(),
  API_PORT: z.coerce.number().default(3001),
  API_HOST: z.string().default('localhost'),
});

export type Environment = z.infer<typeof envSchema>;

// Validate and export environment
export function validateEnv(env: Record<string, string | undefined>): Environment {
  try {
    return envSchema.parse(env);
  } catch (error) {
    if (error instanceof z.ZodError) {
      const missingVars = error.errors
        .filter(e => e.code === 'invalid_type')
        .map(e => e.path.join('.'))
        .join(', ');
      throw new Error(`Invalid environment variables: ${missingVars}`);
    }
    throw error;
  }
}

// Get environment safely
export function getEnv(): Environment {
  return validateEnv(process.env);
}

// AI Configuration defaults
export const AI_DEFAULTS = {
  model: 'claude-3-sonnet' as const,
  maxTokens: 4096,
  temperature: 0.7,
};

// API defaults
export const API_DEFAULTS = {
  timeout: 30000,
  retries: 3,
  retryDelay: 1000,
};
