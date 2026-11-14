import { Test, TestingModule } from '@nestjs/testing';
import { HealthController } from './health.controller';
import { ConfigService } from '@nestjs/config';
import { getConnectionToken } from '@nestjs/mongoose';
import { REDIS_CLIENT } from '../../database/redis.provider';
import { TIMESCALE_POOL } from '../../database/timescale.provider';
import { HttpStatus } from '@nestjs/common';

describe('HealthController', () => {
  let controller: HealthController;

  const createMockResponse = () => {
    const res: any = {};
    res.status = jest.fn().mockReturnValue(res);
    return res;
  };

  it('should return liveness LIVE independent of external dependencies', () => {
    controller = new HealthController();
    const live = controller.getLiveness();
    expect(live.status).toBe('LIVE');
    expect(live.timestamp).toBeDefined();
    expect(live.uptimeSeconds).toBeGreaterThanOrEqual(0);
  });

  describe('MongoDB readiness evaluation', () => {
    it('should return NOT_READY (503) when MongoDB connection is not provided', async () => {
      controller = new HealthController(undefined, undefined, undefined, {
        get: jest.fn().mockReturnValue(false),
      } as any);

      const res = createMockResponse();
      const ready = await controller.getReadiness(res);

      expect(ready.status).toBe('NOT_READY');
      expect(ready.ready).toBe(false);
      expect(ready.dependencies.mongodb.status).toBe('disconnected');
      expect(ready.dependencies.mongodb.required).toBe(true);
      expect(res.status).toHaveBeenCalledWith(HttpStatus.SERVICE_UNAVAILABLE);
    });

    it('should return NOT_READY (503) when MongoDB readyState is 0 (disconnected)', async () => {
      const mockMongo: any = {
        readyState: 0,
      };
      controller = new HealthController(mockMongo, undefined, undefined, {
        get: jest.fn().mockReturnValue(false),
      } as any);

      const res = createMockResponse();
      const ready = await controller.getReadiness(res);

      expect(ready.status).toBe('NOT_READY');
      expect(ready.ready).toBe(false);
      expect(ready.dependencies.mongodb.status).toBe('disconnected');
      expect(res.status).toHaveBeenCalledWith(HttpStatus.SERVICE_UNAVAILABLE);
    });

    it('should return NOT_READY (503) when MongoDB ping fails', async () => {
      const mockMongo: any = {
        readyState: 1,
        db: {
          admin: () => ({
            ping: jest.fn().mockRejectedValue(new Error('Connection timeout')),
          }),
        },
      };
      controller = new HealthController(mockMongo, undefined, undefined, {
        get: jest.fn().mockReturnValue(false),
      } as any);

      const res = createMockResponse();
      const ready = await controller.getReadiness(res);

      expect(ready.status).toBe('NOT_READY');
      expect(ready.ready).toBe(false);
      expect(ready.dependencies.mongodb.status).toBe('unhealthy');
      expect(res.status).toHaveBeenCalledWith(HttpStatus.SERVICE_UNAVAILABLE);
    });

    it('should return READY (200) when MongoDB is connected and optional dependencies are disabled', async () => {
      const mockMongo: any = {
        readyState: 1,
        db: {
          admin: () => ({
            ping: jest.fn().mockResolvedValue({ ok: 1 }),
          }),
        },
      };
      controller = new HealthController(mockMongo, undefined, undefined, {
        get: jest.fn((key: string) => {
          if (key === 'REDIS_ENABLED') return false;
          if (key === 'TIMESCALE_ENABLED') return false;
          return null;
        }),
      } as any);

      const res = createMockResponse();
      const ready = await controller.getReadiness(res);

      expect(ready.status).toBe('READY');
      expect(ready.ready).toBe(true);
      expect(ready.dependencies.mongodb.status).toBe('healthy');
      expect(ready.dependencies.redis.status).toBe('disabled');
      expect(ready.dependencies.timescale.status).toBe('disabled');
      expect(res.status).not.toHaveBeenCalled();
    });
  });

  describe('Redis readiness evaluation', () => {
    const mockHealthyMongo: any = {
      readyState: 1,
      db: { admin: () => ({ ping: jest.fn().mockResolvedValue({ ok: 1 }) }) },
    };

    it('should return READY when Redis is enabled and healthy (PONG)', async () => {
      const mockRedis: any = {
        ping: jest.fn().mockResolvedValue('PONG'),
      };
      controller = new HealthController(mockHealthyMongo, mockRedis, undefined, {
        get: jest.fn((key: string) => (key === 'REDIS_ENABLED' ? true : false)),
      } as any);

      const res = createMockResponse();
      const ready = await controller.getReadiness(res);

      expect(ready.status).toBe('READY');
      expect(ready.ready).toBe(true);
      expect(ready.dependencies.redis.status).toBe('healthy');
      expect(ready.dependencies.redis.required).toBe(true);
      expect(res.status).not.toHaveBeenCalled();
    });

    it('should return NOT_READY (503) when Redis is enabled but ping fails', async () => {
      const mockRedis: any = {
        ping: jest.fn().mockRejectedValue(new Error('ECONNREFUSED')),
      };
      controller = new HealthController(mockHealthyMongo, mockRedis, undefined, {
        get: jest.fn((key: string) => (key === 'REDIS_ENABLED' ? true : false)),
      } as any);

      const res = createMockResponse();
      const ready = await controller.getReadiness(res);

      expect(ready.status).toBe('NOT_READY');
      expect(ready.ready).toBe(false);
      expect(ready.dependencies.redis.status).toBe('unhealthy');
      expect(res.status).toHaveBeenCalledWith(HttpStatus.SERVICE_UNAVAILABLE);
    });

    it('should return NOT_READY (503) when Redis is enabled but client instance is null', async () => {
      controller = new HealthController(mockHealthyMongo, undefined, undefined, {
        get: jest.fn((key: string) => (key === 'REDIS_ENABLED' ? true : false)),
      } as any);

      const res = createMockResponse();
      const ready = await controller.getReadiness(res);

      expect(ready.status).toBe('NOT_READY');
      expect(ready.dependencies.redis.status).toBe('unhealthy');
      expect(res.status).toHaveBeenCalledWith(HttpStatus.SERVICE_UNAVAILABLE);
    });
  });

  describe('TimescaleDB readiness evaluation', () => {
    const mockHealthyMongo: any = {
      readyState: 1,
      db: { admin: () => ({ ping: jest.fn().mockResolvedValue({ ok: 1 }) }) },
    };

    it('should return READY when TimescaleDB is enabled and healthy', async () => {
      const mockPool: any = {
        connect: jest.fn().mockResolvedValue({
          query: jest.fn().mockResolvedValue({ rows: [{ 1: 1 }] }),
          release: jest.fn(),
        }),
      };
      controller = new HealthController(mockHealthyMongo, undefined, mockPool, {
        get: jest.fn((key: string) => (key === 'TIMESCALE_ENABLED' ? true : false)),
      } as any);

      const res = createMockResponse();
      const ready = await controller.getReadiness(res);

      expect(ready.status).toBe('READY');
      expect(ready.ready).toBe(true);
      expect(ready.dependencies.timescale.status).toBe('healthy');
      expect(res.status).not.toHaveBeenCalled();
    });

    it('should return NOT_READY (503) when TimescaleDB is enabled but connection fails', async () => {
      const mockPool: any = {
        connect: jest.fn().mockRejectedValue(new Error('Connection failed')),
      };
      controller = new HealthController(mockHealthyMongo, undefined, mockPool, {
        get: jest.fn((key: string) => (key === 'TIMESCALE_ENABLED' ? true : false)),
      } as any);

      const res = createMockResponse();
      const ready = await controller.getReadiness(res);

      expect(ready.status).toBe('NOT_READY');
      expect(ready.ready).toBe(false);
      expect(ready.dependencies.timescale.status).toBe('unhealthy');
      expect(res.status).toHaveBeenCalledWith(HttpStatus.SERVICE_UNAVAILABLE);
    });
  });

  describe('System health check (/health)', () => {
    it('should return DOWN (503) when MongoDB is disconnected', async () => {
      controller = new HealthController(undefined, undefined, undefined, {
        get: jest.fn().mockReturnValue(false),
      } as any);

      const res = createMockResponse();
      const health = await controller.checkHealth(res);

      expect(health.status).toBe('DOWN');
      expect(health.ready).toBe(false);
      expect(health.components.database).toBe('disconnected');
      expect(res.status).toHaveBeenCalledWith(HttpStatus.SERVICE_UNAVAILABLE);
    });

    it('should return UP (200) when all required dependencies are healthy', async () => {
      const mockMongo: any = {
        readyState: 1,
        db: { admin: () => ({ ping: jest.fn().mockResolvedValue({ ok: 1 }) }) },
      };
      controller = new HealthController(mockMongo, undefined, undefined, {
        get: jest.fn().mockReturnValue(false),
      } as any);

      const res = createMockResponse();
      const health = await controller.checkHealth(res);

      expect(health.status).toBe('UP');
      expect(health.ready).toBe(true);
      expect(health.components.database).toBe('healthy');
      expect(res.status).not.toHaveBeenCalled();
    });
  });

  describe('System metrics (/health/metrics)', () => {
    it('should return UNINSTRUMENTED metrics payload', () => {
      controller = new HealthController();
      const metrics = controller.getMetrics();
      expect(metrics.status).toBe('UNINSTRUMENTED');
      expect(metrics.requestsPerMinute).toBeNull();
      expect(metrics.apiLatencyMsP95).toBeNull();
    });
  });
});
