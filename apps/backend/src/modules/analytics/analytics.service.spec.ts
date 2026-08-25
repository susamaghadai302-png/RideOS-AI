import { Test, TestingModule } from '@nestjs/testing';
import { AnalyticsService } from './analytics.service';

describe('AnalyticsService', () => {
  let service: AnalyticsService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [AnalyticsService],
    }).compile();

    service = module.get<AnalyticsService>(AnalyticsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should return rider performance score', async () => {
    const score = await service.getRiderScore('rider_01');
    expect(score.riderId).toBe('rider_01');
    expect(score.overallSafetyScore).toBeGreaterThan(0);
    expect(score.riderRank).toBe('Apex Master');
  });

  it('should return fleet aggregated summary', async () => {
    const fleet = await service.getFleetSummary('rider_01');
    expect(fleet.totalRides).toBe(42);
    expect(fleet.totalDistanceKm).toBeGreaterThan(1000);
    expect(fleet.recentRides.length).toBeGreaterThanOrEqual(1);
  });
});
