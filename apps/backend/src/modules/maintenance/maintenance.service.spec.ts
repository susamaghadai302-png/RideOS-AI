import { Test, TestingModule } from '@nestjs/testing';
import { MaintenanceService } from './maintenance.service';

describe('MaintenanceService', () => {
  let service: MaintenanceService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [MaintenanceService],
    }).compile();

    service = module.get<MaintenanceService>(MaintenanceService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should log and retrieve maintenance task for bike', async () => {
    const log = await service.logTask(
      'bike_yamaha_r1m',
      'OIL_CHANGE' as any,
      4500,
      5000,
      'Full synthetic Motul 300V oil and OEM filter replaced',
    );

    expect(log.bikeId).toBe('bike_yamaha_r1m');
    expect(log.performedAtKm).toBe(4500);

    const logs = await service.getLogsForBike('bike_yamaha_r1m');
    expect(logs.length).toBeGreaterThanOrEqual(1);
    expect(logs.some((l) => l.taskType === 'OIL_CHANGE')).toBe(true);
  });
});
