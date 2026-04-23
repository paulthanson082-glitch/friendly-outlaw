import { z } from 'zod';
import dotenv from 'dotenv';

dotenv.config();

const DEV_JWT_SECRET = 'dev-secret-key-change-in-production-must-be-32-chars';

const envSchema = z.object({
  PORT: z.coerce.number().default(3000),
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  DATABASE_URL: z.string().url().optional(),
  DATABASE_USE_SQLITE: z.coerce.boolean().default(false),
  SQLITE_PATH: z.string().default('./data/writers_app.db'),
  JWT_SECRET: z
    .string()
    .min(32, 'JWT_SECRET must be at least 32 characters')
    .default(DEV_JWT_SECRET),
  JWT_EXPIRES_IN: z.string().default('7d'),
  ANTHROPIC_API_KEY: z.string().optional().default(''),
  CORS_ORIGIN: z.string().default('http://localhost:3001,http://localhost:5173'),
  LOG_LEVEL: z.enum(['error', 'warn', 'info', 'debug']).default('info'),
});

export type Environment = z.infer<typeof envSchema>;

export const validateEnv = (): Environment => {
  const env = process.env;
  const result = envSchema.safeParse(env);

  if (!result.success) {
    console.error('Environment validation failed:');
    console.error(result.error.flatten());
    process.exit(1);
  }

  const data = result.data;

  // Prevent the development default JWT secret from being used in production
  if (data.NODE_ENV === 'production' && data.JWT_SECRET === DEV_JWT_SECRET) {
    console.error(
      'Error: JWT_SECRET must be set to a unique secret in production.'
    );
    process.exit(1);
  }

  return data;
};

export const config = validateEnv();
