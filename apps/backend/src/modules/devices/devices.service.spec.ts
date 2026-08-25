import { Test, TestingModule } from '@nestjs/testing';
import { DevicesService } from './devices.service';
import { DeviceProtocolType } from './dto/connect-device.dto';

describe('DevicesService', () => {
  let service: DevicesService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [DevicesService],
    }).compile();

    service = module.get<DevicesService>(DevicesService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should list registered devices including simulator', async () => {
    const list = await service.listDevices();
    expect(list.length).toBeGreaterThanOrEqual(1);
    expect(list.some((d) => d.protocolType === DeviceProtocolType.SIMULATOR)).toBe(true);
  });

  it('should connect new device and return capabilities', async () => {
    const device = await service.connectDevice('rider_1', {
      deviceId: 'dev_yamaha_01',
      deviceName: 'Yamaha CCU Link',
      protocolType: DeviceProtocolType.YAMAHA_CCU,
      macAddress: 'AA:BB:CC:11:22:33',
    });

    expect(device.isConnected).toBe(true);
    expect(device.capabilities.canStreamSpeed).toBe(true);
  });

  it('should manage telemetry recording session', async () => {
    const session = await service.startSession('rider_1', {
      deviceId: 'dev_sim_01',
      isSimulated: true,
    });

    expect(session.sessionId).toBeDefined();
    expect(session.status).toBe('RECORDING');

    const stopped = await service.stopSession(session.sessionId, {
      totalDistanceKm: 12.4,
      totalSamplesRecorded: 250,
      averageSpeedKmh: 52.0,
    });

    expect(stopped.status).toBe('COMPLETED');
    expect(stopped.summary?.totalDistanceKm).toBe(12.4);
  });
});
