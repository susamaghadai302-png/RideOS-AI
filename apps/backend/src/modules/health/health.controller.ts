import { Controller, Get, Inject, Optional, Res, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';
import { InjectConnection } from '@nestjs/mongoose';
import { Connection } from 'mongoose';
import { Response } from 'express';
import { REDIS_CLIENT } from '../../database/redis.provider';
import { TIMESCALE_POOL } from '../../database/timescale.provider';
import { Redis } from 'ioredis';
import { Pool } from 'pg';

@ApiTags('Health & Monitoring')
@Controller('health')
export class HealthController {
  constructor(
    @Optional() @InjectConnection() private readonly mongoConnection?: Connection,
    @Optional() @Inject(REDIS_CLIENT) private readonly redisClient?: Redis,
    @Optional() @Inject(TIMESCALE_POOL) private readonly dbPool?: Pool,
    @Optional() private readonly configService?: ConfigService,
  ) {}

  /**
   * Internal dependency evaluator that rigorously inspects required and optional infrastructure
   */
  private async evaluateDependencies() {
    const redisEnabled = this.configService?.get<boolean>('REDIS_ENABLED') ?? false;
    const timescaleEnabled = this.configService?.get<boolean>('TIMESCALE_ENABLED') ?? false;

    // 1. Evaluate MongoDB (Strictly required primary production store)
    let mongoStatus: 'healthy' | 'connecting' | 'disconnected' | 'unhealthy' = 'disconnected';
    let mongoError: string | null = null;

    if (this.mongoConnection) {
      // Mongoose readyState: 0 = disconnected, 1 = connected, 2 = connecting, 3 = disconnecting
      if (this.mongoConnection.readyState === 1) {
        try {
          if (this.mongoConnection.db) {
            await this.mongoConnection.db.admin().ping();
            mongoStatus = 'healthy';
          } else {
            mongoStatus = 'healthy';
          }
        } catch (err: any) {
          mongoStatus = 'unhealthy';
          mongoError = err?.message || 'MongoDB ping check failed';
        }
      } else if (this.mongoConnection.readyState === 2) {
        mongoStatus = 'connecting';
        mongoError = 'MongoDB connection in progress';
      } else {
        mongoStatus = 'disconnected';
        mongoError = `MongoDB is disconnected (readyState=${this.mongoConnection.readyState})`;
      }
    } else {
      mongoStatus = 'disconnected';
      mongoError = 'MongoDB connection provider not available';
    }

    // 2. Evaluate Redis (Optional unless REDIS_ENABLED=true)
    let redisStatus: 'healthy' | 'degraded' | 'unhealthy' | 'disabled' = 'disabled';
    let redisError: string | null = null;

    if (redisEnabled) {
      if (this.redisClient) {
        try {
          const ping = await this.redisClient.ping();
          if (ping === 'PONG') {
            redisStatus = 'healthy';
          } else {
            redisStatus = 'degraded';
            redisError = `Unexpected ping response: ${ping}`;
          }
        } catch (err: any) {
          redisStatus = 'unhealthy';
          redisError = err?.message || 'Redis ping failed';
        }
      } else {
        redisStatus = 'unhealthy';
        redisError = 'REDIS_ENABLED is true but Redis client instance is null';
      }
    }

    // 3. Evaluate TimescaleDB (Optional unless TIMESCALE_ENABLED=true)
    let timescaleStatus: 'healthy' | 'unhealthy' | 'disabled' = 'disabled';
    let timescaleError: string | null = null;

    if (timescaleEnabled) {
      if (this.dbPool) {
        try {
          const client = await this.dbPool.connect();
          await client.query('SELECT 1');
          client.release();
          timescaleStatus = 'healthy';
        } catch (err: any) {
          timescaleStatus = 'unhealthy';
          timescaleError = err?.message || 'TimescaleDB query failed';
        }
      } else {
        timescaleStatus = 'unhealthy';
        timescaleError = 'TIMESCALE_ENABLED is true but TimescaleDB pool instance is null';
      }
    }

    // Overall readiness verdict:
    // - MongoDB is always required.
    // - If Redis is enabled, it must be healthy.
    // - If TimescaleDB is enabled, it must be healthy.
    const isMongoReady = mongoStatus === 'healthy';
    const isRedisReady = !redisEnabled || redisStatus === 'healthy';
    const isTimescaleReady = !timescaleEnabled || timescaleStatus === 'healthy';

    const isReady = isMongoReady && isRedisReady && isTimescaleReady;

    return {
      isReady,
      dependencies: {
        mongodb: {
          status: mongoStatus,
          required: true,
          error: mongoError,
        },
        redis: {
          status: redisStatus,
          required: redisEnabled,
          enabled: redisEnabled,
          error: redisError,
        },
        timescale: {
          status: timescaleStatus,
          required: timescaleEnabled,
          enabled: timescaleEnabled,
          error: timescaleError,
        },
      },
    };
  }

  @Get()
  @ApiOperation({ summary: 'System Health Check' })
  @ApiResponse({ status: 200, description: 'System is healthy and ready' })
  @ApiResponse({ status: 503, description: 'System is down or degraded' })
  async checkHealth(@Res({ passthrough: true }) res?: Response) {
    const memoryUsage = process.memoryUsage();
    const { isReady, dependencies } = await this.evaluateDependencies();

    if (!isReady && res) {
      res.status(HttpStatus.SERVICE_UNAVAILABLE);
    }

    return {
      status: isReady ? 'UP' : 'DOWN',
      ready: isReady,
      timestamp: new Date().toISOString(),
      service: 'RideOS-AI-Backend',
      version: '1.0.0',
      uptimeSeconds: process.uptime(),
      components: {
        database: dependencies.mongodb.status,
        redis: dependencies.redis.status,
        timescale: dependencies.timescale.status,
      },
      dependencies,
      system: {
        heapUsedMB: Math.round(memoryUsage.heapUsed / 1024 / 1024),
        heapTotalMB: Math.round(memoryUsage.heapTotal / 1024 / 1024),
        rssMB: Math.round(memoryUsage.rss / 1024 / 1024),
      },
    };
  }

  @Get('/liveness')
  @ApiOperation({ summary: 'Container Liveness Probe' })
  @ApiResponse({ status: 200, description: 'Container runtime is live' })
  getLiveness() {
    return {
      status: 'LIVE',
      timestamp: new Date().toISOString(),
      uptimeSeconds: process.uptime(),
    };
  }

  @Get('/readiness')
  @ApiOperation({ summary: 'Container Readiness Probe' })
  @ApiResponse({ status: 200, description: 'Service is ready to accept production traffic' })
  @ApiResponse({ status: 503, description: 'Service is not ready (required dependencies unavailable)' })
  async getReadiness(@Res({ passthrough: true }) res?: Response) {
    const { isReady, dependencies } = await this.evaluateDependencies();

    if (!isReady && res) {
      res.status(HttpStatus.SERVICE_UNAVAILABLE);
    }

    return {
      status: isReady ? 'READY' : 'NOT_READY',
      ready: isReady,
      timestamp: new Date().toISOString(),
      service: 'RideOS-AI-Backend',
      dependencies,
    };
  }

  @Get('/metrics')
  @ApiOperation({ summary: 'System Telemetry Metrics' })
  getMetrics() {
    return {
      status: 'UNINSTRUMENTED',
      message: 'Request, latency, and CPU metrics are not instrumented in this service.',
      timestamp: new Date().toISOString(),
      activeConnections: null,
      apiLatencyMsP95: null,
      requestsPerMinute: null,
      cpuUsagePct: null,
    };
  }
}
