import { Test, TestingModule } from '@nestjs/testing';
import { getModelToken } from '@nestjs/mongoose';
import { ObdDiagnosticsService } from './obd_diagnostics.service';
import { DiagnosticLog } from './schemas/diagnostic-log.schema';

describe('ObdDiagnosticsService', () => {
  let service: ObdDiagnosticsService;

  const mockLogModel = function (dto: any) {
    this._id = 'log-123';
    this.riderId = dto.riderId;
    this.rpm = dto.rpm;
    this.tpmsWarning = dto.tpmsWarning;
    this.tpmsMessage = dto.tpmsMessage;
    this.save = jest.fn().mockResolvedValue(this);
  };
  mockLogModel.findOne = jest.fn().mockReturnValue({
    sort: jest.fn().mockReturnValue({
      exec: jest.fn().mockResolvedValue({
        _id: 'log-123',
        riderId: 'rider-1',
        rpm: 4200,
        engineTempC: 88,
        batteryVoltage: 12.6,
        frontTirePsi: 24.5,
        rearTirePsi: 32.0,
        diagnosticCodes: ['P0300'],
        tpmsWarning: true,
        tpmsMessage: 'LOW TIRE PRESSURE WARNING: Front 24.5 PSI | Rear 32.0 PSI',
      }),
    }),
  });

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ObdDiagnosticsService,
        { provide: getModelToken(DiagnosticLog.name), useValue: mockLogModel },
      ],
    }).compile();

    service = module.get<ObdDiagnosticsService>(ObdDiagnosticsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should trigger TPMS low pressure warning when tire PSI < 28', async () => {
    const result = await service.processObdData('rider-1', {
      rpm: 3500,
      engineTempC: 85,
      throttlePct: 40,
      batteryVoltage: 12.4,
      frontTirePsi: 25.0,
      rearTirePsi: 32.0,
      diagnosticCodes: [],
    });

    expect(result.tpmsWarning).toBe(true);
    expect(result.tpmsMessage).toContain('LOW TIRE PRESSURE WARNING');
  });
});
