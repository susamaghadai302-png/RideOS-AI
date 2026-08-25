import { Test, TestingModule } from '@nestjs/testing';
import { HealthController } from './health.controller';

describe('HealthController', () => {
  let controller: HealthController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [HealthController],
      providers: [],
    }).compile();

    controller = module.get<HealthController>(HealthController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  it('should return system health UP status', async () => {
    const res = await controller.checkHealth();
    expect(res.status).toEqual('UP');
    expect(res.service).toEqual('RideOS-AI-Backend');
    expect(res.uptimeSeconds).toBeGreaterThanOrEqual(0);
    expect(res.system).toBeDefined();
  });

  it('should return liveness and readiness status', async () => {
    const live = controller.getLiveness();
    expect(live.status).toBe('LIVE');

    const ready = await controller.getReadiness();
    expect(ready.status).toBe('READY');
  });

  it('should return system metrics', () => {
    const metrics = controller.getMetrics();
    expect(metrics.activeConnections).toBeDefined();
    expect(metrics.requestsPerMinute).toBeGreaterThan(0);
  });
});
