import { Test, TestingModule } from '@nestjs/testing';
import { AnalyticsService } from './analytics.service';
import { TripsService } from '../trips/trips.service';

describe('AnalyticsService', () => {
  let service: AnalyticsService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AnalyticsService,
        {
          provide: TripsService,
          useValue: {
            getUserTrips: jest.fn().mockResolvedValue({
              trips: [
                { tripId: 'trip_1', distanceKm: 600, durationSeconds: 3600, maxSpeedKmh: 120, startTime: new Date() },
                { tripId: 'trip_2', distanceKm: 600, durationSeconds: 3600, maxSpeedKmh: 130, startTime: new Date() },
              ]
            }),
          },
        },
      ],
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
    expect(score.riderRank).toBe('Active Rider');
  });

  it('should return fleet aggregated summary', async () => {
    const fleet = await service.getFleetSummary('rider_01');
    expect(fleet.totalRides).toBe(2);
    expect(fleet.totalDistanceKm).toBeGreaterThan(1000);
    expect(fleet.recentRides.length).toBe(2);
  });
});
