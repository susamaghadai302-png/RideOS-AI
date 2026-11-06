import { Module, Global } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ConfigService } from '@nestjs/config';
import { RedisProvider, REDIS_CLIENT } from './redis.provider';
import { TimescaleProvider, TIMESCALE_POOL } from './timescale.provider';

@Global()
@Module({
  imports: [
    MongooseModule.forRootAsync({
      useFactory: (configService: ConfigService) => ({
        uri: configService.get<string>('MONGO_URI', 'mongodb://localhost:27017/rideos'),
        lazyConnection: true,
        serverSelectionTimeoutMS: 2000,
        connectTimeoutMS: 2000,
        onConnectionCreate: (connection) => {
          connection.on('error', (err) => {
            console.warn('[MongoDB] Connection warning (running without MongoDB):', err.message);
          });
          connection.on('connected', () => {
            console.log('[MongoDB] Connected successfully to database');
          });
        },
      }),
      inject: [ConfigService],
    }),
  ],
  providers: [RedisProvider, TimescaleProvider],
  exports: [REDIS_CLIENT, TIMESCALE_POOL, MongooseModule],
})
export class DatabaseModule {}
