import { Test, TestingModule } from '@nestjs/testing';
import { TelematicsService } from './telematics.service';
import { TIMESCALE_POOL } from '../../database/timescale.provider';
import { TelemetryBatchWriterService } from './services/telemetry-batch-writer.service';
import { LeanAngleCalculatorService } from './services/lean-angle-calculator.service';

describe('TelematicsService', () => {
  let service: TelematicsService;

  const mockTimescalePool = {
    query: jest.fn().mockResolvedValue({
      rows: [
        {
          total_points: '150',
          avg_speed: 64.5,
          max_speed: 112.0,
          max_lean_angle: 42.5,
          max_accel_g: 1.8,
        },
      ],
    }),
  };

  const mockBatchWriter = {
    enqueueTelemetry: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TelematicsService,
        { provide: TIMESCALE_POOL, useValue: mockTimescalePool },
        { provide: TelemetryBatchWriterService, useValue: mockBatchWriter },
        LeanAngleCalculatorService,
      ],
    }).compile();

    service = module.get<TelematicsService>(TelematicsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should enqueue telemetry for batch writing', () => {
    const result = service.processTelemetry('rider-1', {
      tripId: 'trip-1',
      timestamp: new Date().toISOString(),
      lat: 37.7749,
      lng: -122.4194,
      speedKmh: 75.0,
      leanAngle: 28.5,
      accelG: 1.2,
    });

    expect(result.status).toEqual('QUEUED');
    expect(mockBatchWriter.enqueueTelemetry).toHaveBeenCalled();
  });

  it('should fetch trip summary analytics', async () => {
    const summary = await service.getTripSummary('trip-1');
    expect(summary.total_points).toEqual('150');
    expect(summary.max_lean_angle).toEqual(42.5);
  });
});
