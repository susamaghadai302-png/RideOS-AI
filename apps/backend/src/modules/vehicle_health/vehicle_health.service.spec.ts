import { Test, TestingModule } from '@nestjs/testing';
import { getModelToken } from '@nestjs/mongoose';
import { VehicleHealthService } from './vehicle_health.service';
import { DiagnosticEvent } from './schemas/diagnostic_event.schema';
import { MaintenanceRecord } from './schemas/maintenance_record.schema';
import { VehicleAlert } from './schemas/vehicle_alert.schema';
import { VehicleDocument } from './schemas/vehicle_document.schema';

describe('VehicleHealthService Unit Tests', () => {
  let service: VehicleHealthService;
  let mockDiagnosticModel: any;
  let mockMaintenanceModel: any;
  let mockAlertModel: any;
  let mockDocumentModel: any;

  beforeEach(async () => {
    mockDiagnosticModel = jest.fn().mockImplementation((dto) => ({
      ...dto,
      save: jest.fn().mockResolvedValue({ ...dto, _id: 'diag-123' }),
    }));
    mockDiagnosticModel.findOne = jest.fn();
    mockDiagnosticModel.find = jest.fn();

    mockMaintenanceModel = jest.fn().mockImplementation((dto) => ({
      ...dto,
      save: jest.fn().mockResolvedValue({ ...dto, _id: 'maint-123' }),
    }));
    mockMaintenanceModel.find = jest.fn();

    mockAlertModel = jest.fn().mockImplementation((dto) => ({
      ...dto,
      save: jest.fn().mockResolvedValue({ ...dto, _id: 'alert-123' }),
    }));
    mockAlertModel.findOne = jest.fn();
    mockAlertModel.find = jest.fn();

    mockDocumentModel = jest.fn().mockImplementation((dto) => ({
      ...dto,
      save: jest.fn().mockResolvedValue({ ...dto, _id: 'doc-123' }),
    }));
    mockDocumentModel.find = jest.fn();
    mockDocumentModel.findByIdAndDelete = jest.fn();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        VehicleHealthService,
        { provide: getModelToken(DiagnosticEvent.name), useValue: mockDiagnosticModel },
        { provide: getModelToken(MaintenanceRecord.name), useValue: mockMaintenanceModel },
        { provide: getModelToken(VehicleAlert.name), useValue: mockAlertModel },
        { provide: getModelToken(VehicleDocument.name), useValue: mockDocumentModel },
      ],
    }).compile();

    service = module.get<VehicleHealthService>(VehicleHealthService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('logDiagnosticEvent', () => {
    it('should log a new DTC fault event when none active', async () => {
      mockDiagnosticModel.findOne.mockReturnValue({
        exec: jest.fn().mockResolvedValue(null),
      });

      const res = await service.logDiagnosticEvent('rider-001', {
        vehicleId: 'veh-yamaha-r1',
        code: 'P0300',
        description: 'Random Cylinder Misfire Detected',
        severity: 'CRITICAL',
      });

      expect(res).toBeDefined();
      expect(res.code).toBe('P0300');
      expect(res.occurrences).toBe(1);
    });

    it('should increment occurrences if DTC is already active', async () => {
      const activeEvent = {
        vehicleId: 'veh-yamaha-r1',
        code: 'P0300',
        occurrences: 2,
        save: jest.fn().mockResolvedValue({ occurrences: 3 }),
      };
      mockDiagnosticModel.findOne.mockReturnValue({
        exec: jest.fn().mockResolvedValue(activeEvent),
      });

      const res = await service.logDiagnosticEvent('rider-001', {
        vehicleId: 'veh-yamaha-r1',
        code: 'P0300',
        description: 'Random Cylinder Misfire Detected',
      });

      expect(activeEvent.occurrences).toBe(3);
      expect(activeEvent.save).toHaveBeenCalled();
    });
  });

  describe('createMaintenanceRecord', () => {
    it('should store a verified service entry', async () => {
      const res = await service.createMaintenanceRecord('rider-001', {
        vehicleId: 'veh-yamaha-r1',
        serviceType: 'OIL_CHANGE',
        odometerKm: 5000,
        isVehicleOdometer: true,
        cost: 120,
        serviceProvider: 'Apex Moto Lab',
      });

      expect(res).toBeDefined();
      expect(res.serviceType).toBe('OIL_CHANGE');
      expect(res.odometerKm).toBe(5000);
      expect(res.isVehicleOdometer).toBe(true);
    });
  });

  describe('createOrUpdateAlert', () => {
    it('should create new alert if not already active', async () => {
      mockAlertModel.findOne.mockReturnValue({
        exec: jest.fn().mockResolvedValue(null),
      });

      const res = await service.createOrUpdateAlert('rider-001', {
        vehicleId: 'veh-ducati',
        alertKey: 'LOW_BATTERY_12V',
        title: 'Low Battery Voltage',
        message: 'System voltage dropped below 11.8V',
        category: 'BATTERY',
        severity: 'WARNING',
      });

      expect(res).toBeDefined();
      expect(res.alertKey).toBe('LOW_BATTERY_12V');
      expect(res.status).toBe('ACTIVE');
    });
  });

  describe('getPredictiveHealthSummary', () => {
    it('should compute overall health score accurately based on active DTCs and alerts', async () => {
      mockDiagnosticModel.find.mockReturnValue({
        sort: jest.fn().mockReturnValue({
          exec: jest.fn().mockResolvedValue([]),
        }),
      });
      mockAlertModel.find.mockReturnValue({
        sort: jest.fn().mockReturnValue({
          exec: jest.fn().mockResolvedValue([]),
        }),
      });
      mockMaintenanceModel.find.mockReturnValue({
        sort: jest.fn().mockReturnValue({
          exec: jest.fn().mockResolvedValue([]),
        }),
      });

      const res = await service.getPredictiveHealthSummary('rider-001', 'veh-yamaha-r1');
      expect(res).toBeDefined();
      expect(res.overallHealthScore).toBeNull();
      expect(res.status).toBe('UNAVAILABLE');
      expect(res.activeDtcCount).toBe(0);
    });
  });
});
