import { Module, Global } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ConfigService } from '@nestjs/config';
import { Connection } from 'mongoose';
import { RedisProvider, REDIS_CLIENT } from './redis.provider';
import { TimescaleProvider, TIMESCALE_POOL } from './timescale.provider';

@Global()
@Module({
  imports: [
    MongooseModule.forRootAsync({
      useFactory: (configService: ConfigService) => ({
        uri: configService.get<string>('MONGO_URI', 'mongodb://localhost:27017/rideos'),
        lazyConnection: true,
        serverSelectionTimeoutMS: 3000,
        connectTimeoutMS: 3000,
        connectionFactory: (connection: Connection) => {
          connection.on('error', (err: any) => {
            console.warn('[MongoDB] Connection warning (database unavailable):', err?.message || err);
          });
          connection.on('connected', () => {
            console.log('[MongoDB] Connected successfully to database');
          });
          return connection;
        },
      }),
      inject: [ConfigService],
    }),
  ],
  providers: [RedisProvider, TimescaleProvider],
  exports: [REDIS_CLIENT, TIMESCALE_POOL, MongooseModule],
})
export class DatabaseModule {}
