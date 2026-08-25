import { Provider } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

export const REDIS_CLIENT = 'REDIS_CLIENT';

export const RedisProvider: Provider = {
  provide: REDIS_CLIENT,
  useFactory: (configService: ConfigService) => {
    const isEnabled = configService.get<boolean>('REDIS_ENABLED', false);
    if (!isEnabled) {
      return null;
    }

    const host = configService.get<string>('REDIS_HOST', '127.0.0.1');
    const port = configService.get<number>('REDIS_PORT', 6379);

    const client = new Redis({
      host,
      port,
      lazyConnect: true,
      maxRetriesPerRequest: 1,
      enableOfflineQueue: false,
      retryStrategy: (times) => {
        if (times > 3) {
          return null; // Stop retrying to prevent continuous error logs
        }
        return Math.min(times * 200, 2000);
      },
    });

    client.on('connect', () => {
      console.log(`[Redis] Connected successfully to ${host}:${port}`);
    });

    client.on('error', (err) => {
      console.warn('[Redis] Connection warning:', err.message);
    });

    return client;
  },
  inject: [ConfigService],
};
