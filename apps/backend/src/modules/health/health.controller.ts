import { Controller, Get, Inject, Optional } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { REDIS_CLIENT } from '../../database/redis.provider';
import { TIMESCALE_POOL } from '../../database/timescale.provider';
import { Redis } from 'ioredis';
import { Pool } from 'pg';

@ApiTags('Health & Monitoring')
@Controller('health')
export class HealthController {
  constructor(
    @Optional() @Inject(REDIS_CLIENT) private readonly redisClient?: Redis,
    @Optional() @Inject(TIMESCALE_POOL) private readonly dbPool?: Pool,
  ) {}

  @Get()
  @ApiOperation({ summary: 'System Health Check' })
  @ApiResponse({ status: 200, description: 'System is healthy' })
  async checkHealth() {
    const memoryUsage = process.memoryUsage();
    let redisStatus = 'disabled';
    let dbStatus = 'disabled';

    if (this.redisClient) {
      try {
        const ping = await this.redisClient.ping();
        redisStatus = ping === 'PONG' ? 'healthy' : 'degraded';
      } catch (err: any) {
        redisStatus = 'down';
      }
    }

    if (this.dbPool) {
      try {
        const client = await this.dbPool.connect();
        await client.query('SELECT 1');
        client.release();
        dbStatus = 'healthy';
      } catch (err: any) {
        dbStatus = 'degraded';
      }
    }

    return {
      status: 'UP',
      timestamp: new Date().toISOString(),
      service: 'RideOS-AI-Backend',
      version: '1.0.0',
      uptimeSeconds: process.uptime(),
      components: {
        database: dbStatus,
        redis: redisStatus,
      },
      system: {
        heapUsedMB: Math.round(memoryUsage.heapUsed / 1024 / 1024),
        heapTotalMB: Math.round(memoryUsage.heapTotal / 1024 / 1024),
        rssMB: Math.round(memoryUsage.rss / 1024 / 1024),
      },
    };
  }

  @Get('/liveness')
  @ApiOperation({ summary: 'Container Liveness Probe' })
  getLiveness() {
    return { status: 'LIVE', timestamp: new Date().toISOString() };
  }

  @Get('/readiness')
  @ApiOperation({ summary: 'Container Readiness Probe' })
  async getReadiness() {
    let isReady = true;
    if (this.dbPool) {
      try {
        const client = await this.dbPool.connect();
        await client.query('SELECT 1');
        client.release();
      } catch {
        isReady = false;
      }
    }
    return {
      status: isReady ? 'READY' : 'DEGRADED',
      timestamp: new Date().toISOString(),
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
