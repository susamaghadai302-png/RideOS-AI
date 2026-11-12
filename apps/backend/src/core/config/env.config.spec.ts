import { validateEnv } from './env.config';

describe('validateEnv', () => {
  it('should accept valid development configuration with defaults', () => {
    const env = validateEnv({
      NODE_ENV: 'development',
    });
    expect(env.NODE_ENV).toBe('development');
    expect(env.PORT).toBe(3000);
    expect(env.REDIS_ENABLED).toBe(false);
    expect(env.TIMESCALE_ENABLED).toBe(false);
  });

  it('should reject insecure JWT secret in production', () => {
    expect(() =>
      validateEnv({
        NODE_ENV: 'production',
        JWT_SECRET: 'super_secret_rideos_jwt_key_2026',
        JWT_REFRESH_SECRET: 'a_very_strong_refresh_secret_that_is_long_2026!',
        MONGO_URI: 'mongodb+srv://user:pass@cluster.mongodb.net/rideos',
      }),
    ).toThrow('[RideOS] FATAL: JWT_SECRET is set to an insecure default value.');
  });

  it('should reject insecure JWT refresh secret in production', () => {
    expect(() =>
      validateEnv({
        NODE_ENV: 'production',
        JWT_SECRET: 'a_very_strong_access_secret_that_is_long_2026!',
        JWT_REFRESH_SECRET: 'super_secret_rideos_refresh_key_2026',
        MONGO_URI: 'mongodb+srv://user:pass@cluster.mongodb.net/rideos',
      }),
    ).toThrow('[RideOS] FATAL: JWT_REFRESH_SECRET is set to an insecure default value.');
  });

  it('should reject localhost MONGO_URI in production', () => {
    expect(() =>
      validateEnv({
        NODE_ENV: 'production',
        JWT_SECRET: 'a_very_strong_access_secret_that_is_long_2026!',
        JWT_REFRESH_SECRET: 'a_very_strong_refresh_secret_that_is_long_2026!',
        MONGO_URI: 'mongodb://127.0.0.1:27017/rideos',
      }),
    ).toThrow('[RideOS] FATAL: MONGO_URI must not point to localhost in production.');
  });

  it('should reject localhost REDIS_HOST when REDIS_ENABLED=true in production', () => {
    expect(() =>
      validateEnv({
        NODE_ENV: 'production',
        JWT_SECRET: 'a_very_strong_access_secret_that_is_long_2026!',
        JWT_REFRESH_SECRET: 'a_very_strong_refresh_secret_that_is_long_2026!',
        MONGO_URI: 'mongodb+srv://user:pass@cluster.mongodb.net/rideos',
        REDIS_ENABLED: 'true',
        REDIS_HOST: '127.0.0.1',
      }),
    ).toThrow('[RideOS] FATAL: REDIS_HOST must not point to localhost when REDIS_ENABLED=true in production.');
  });

  it('should reject localhost TIMESCALE_HOST when TIMESCALE_ENABLED=true in production', () => {
    expect(() =>
      validateEnv({
        NODE_ENV: 'production',
        JWT_SECRET: 'a_very_strong_access_secret_that_is_long_2026!',
        JWT_REFRESH_SECRET: 'a_very_strong_refresh_secret_that_is_long_2026!',
        MONGO_URI: 'mongodb+srv://user:pass@cluster.mongodb.net/rideos',
        TIMESCALE_ENABLED: 'true',
        TIMESCALE_HOST: 'localhost',
      }),
    ).toThrow('[RideOS] FATAL: TIMESCALE_HOST must not point to localhost when TIMESCALE_ENABLED=true in production.');
  });

  it('should accept valid production configuration with external services', () => {
    const env = validateEnv({
      NODE_ENV: 'production',
      JWT_SECRET: 'a_very_strong_access_secret_that_is_long_2026!',
      JWT_REFRESH_SECRET: 'a_very_strong_refresh_secret_that_is_long_2026!',
      MONGO_URI: 'mongodb+srv://user:pass@cluster.mongodb.net/rideos',
      REDIS_ENABLED: 'true',
      REDIS_HOST: 'redis.internal.cache.google.com',
      TIMESCALE_ENABLED: 'false',
    });
    expect(env.NODE_ENV).toBe('production');
    expect(env.REDIS_ENABLED).toBe(true);
    expect(env.TIMESCALE_ENABLED).toBe(false);
  });
});
