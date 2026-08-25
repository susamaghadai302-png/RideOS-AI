import { Test, TestingModule } from '@nestjs/testing';
import { CloudSyncService } from './cloud-sync.service';
import { SyncDataSource } from './dto/sync-ride-payload.dto';

describe('CloudSyncService', () => {
  let service: CloudSyncService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [CloudSyncService],
    }).compile();

    service = module.get<CloudSyncService>(CloudSyncService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should sync ride session and prevent duplicate uploads', async () => {
    const payload = {
      sessionId: 'sess_test_1001',
      riderId: 'rider_apex_1',
      startTime: new Date().toISOString(),
      endTime: new Date().toISOString(),
      totalDistanceKm: 18.5,
      durationMinutes: 24.0,
      maxSpeedKmh: 122.0,
      averageSpeedKmh: 46.25,
      maxRpm: 9800,
      averageRpm: 5400,
      maxLeanAngleDeg: 38.5,
      dataSource: SyncDataSource.REAL_DEVICE,
    };

    const firstResult = await service.syncRideSession(payload);
    expect(firstResult.status).toBe('SYNCED');
    expect(firstResult.isDuplicate).toBe(false);

    // Duplicate sync attempt
    const dupResult = await service.syncRideSession(payload);
    expect(dupResult.status).toBe('SYNCED');
    expect(dupResult.isDuplicate).toBe(true);

    const status = await service.getSyncStatus('rider_apex_1');
    expect(status.serverStatus).toBe('ONLINE');
    expect(status.totalSyncedSessions).toBeGreaterThanOrEqual(1);
  });
});
