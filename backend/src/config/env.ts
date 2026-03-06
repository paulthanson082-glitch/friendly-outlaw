import { z } from 'zod';

const envSchema = z.object({
  PORT: z.coerce.number().default(3000),
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  DATABASE_URL: z.string().url().optional(),
  DATABASE_USE_SQLITE: z.coerce.boolean().default(false),
  SQLITE_PATH: z.string().default('./data/writers_app.db'),
  JWT_SECRET: z.string().min(32, 'JWT_SECRET must be at least 32 characters'),
  JWT_EXPIRES_IN: z.string().default('7d'),
  ANTHROPIC_API_KEY: z.string().min(1, 'ANTHROPIC_API_KEY is required'),
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

  return result.data;
};

export const config = validateEnv();
