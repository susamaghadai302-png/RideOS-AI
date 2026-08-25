import { z } from 'zod';

const INSECURE_JWT_DEFAULTS = [
  'super_secret_rideos_jwt_key_2026',
  'super_secret_rideos_refresh_key_2026',
];

export const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.coerce.number().default(3000),
  MONGO_URI: z.string().default('mongodb://127.0.0.1:27017/rideos'),
  REDIS_ENABLED: z
    .preprocess((val) => {
      if (typeof val === 'string') {
        return val.toLowerCase() === 'true' || val === '1';
      }
      return Boolean(val);
    }, z.boolean())
    .default(false),
  REDIS_HOST: z.string().default('127.0.0.1'),
  REDIS_PORT: z.coerce.number().default(6379),
  TIMESCALE_HOST: z.string().default('127.0.0.1'),
  TIMESCALE_PORT: z.coerce.number().default(5432),
  TIMESCALE_USER: z.string().default('rideos_admin'),
  TIMESCALE_PASSWORD: z.string().default('rideos_secure_password'),
  TIMESCALE_DB: z.string().default('rideos_telemetry'),
  JWT_SECRET: z.string().default('super_secret_rideos_jwt_key_2026'),
  JWT_EXPIRATION: z.string().default('7d'),
  JWT_REFRESH_SECRET: z.string().default('super_secret_rideos_refresh_key_2026'),
  GEMINI_API_KEY: z.string().optional(),
  GOOGLE_MAPS_API_KEY: z.string().optional(),
  MAPBOX_ACCESS_TOKEN: z.string().optional(),
  GOOGLE_CLIENT_ID: z.string().optional(),
  APPLE_CLIENT_ID: z.string().optional(),
  TWILIO_ACCOUNT_SID: z.string().optional(),
  TWILIO_AUTH_TOKEN: z.string().optional(),
  TWILIO_FROM_PHONE: z.string().optional(),
  FIREBASE_PROJECT_ID: z.string().optional(),
  FIREBASE_CLIENT_EMAIL: z.string().optional(),
  FIREBASE_PRIVATE_KEY: z.string().optional(),
  FIREBASE_SERVER_KEY: z.string().optional(),
});

export type EnvConfig = z.infer<typeof envSchema>;

export function validateEnv(config: Record<string, unknown>): EnvConfig {
  const result = envSchema.safeParse(config);
  if (!result.success) {
    console.error('Invalid environment variables schema:', result.error.format());
    throw new Error('Environment configuration validation failed');
  }

  const env = result.data;

  // Refuse to start in production with known-insecure default secrets.
  if (env.NODE_ENV === 'production') {
    if (INSECURE_JWT_DEFAULTS.includes(env.JWT_SECRET)) {
      throw new Error(
        '[RideOS] FATAL: JWT_SECRET is set to an insecure default value. ' +
        'Set a cryptographically random JWT_SECRET before deploying to production.',
      );
    }
    if (INSECURE_JWT_DEFAULTS.includes(env.JWT_REFRESH_SECRET)) {
      throw new Error(
        '[RideOS] FATAL: JWT_REFRESH_SECRET is set to an insecure default value. ' +
        'Set a cryptographically random JWT_REFRESH_SECRET before deploying to production.',
      );
    }
  }

  return env;
}
