import { Test, TestingModule } from '@nestjs/testing';
import { DiagnosticsService } from './diagnostics.service';
import { getModelToken } from '@nestjs/mongoose';
import { DiagnosticScan } from './schemas/diagnostic-scan.schema';
import { VehiclesService } from '../vehicles/vehicles.service';
import { NotFoundException, BadRequestException } from '@nestjs/common';
import { Types } from 'mongoose';
import { DiagnosticsDecoder } from './diagnostics.decoder';

describe('DiagnosticsService', () => {
  let service: DiagnosticsService;
  let vehiclesService: VehiclesService;
  let decoder: DiagnosticsDecoder;

  class MockScanModel {
    constructor(private data: any) {
      Object.assign(this, data);
    }
    save = jest.fn().mockResolvedValue(this);
    static find = jest.fn().mockReturnThis();
    static sort = jest.fn().mockReturnThis();
    static limit = jest.fn().mockReturnThis();
    static exec = jest.fn().mockResolvedValue([]);
  }

  const mockVehiclesService = {
    findOne: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DiagnosticsService,
        DiagnosticsDecoder,
        {
          provide: getModelToken(DiagnosticScan.name),
          useValue: MockScanModel,
        },
        {
          provide: VehiclesService,
          useValue: mockVehiclesService,
        },
      ],
    }).compile();

    service = module.get<DiagnosticsService>(DiagnosticsService);
    vehiclesService = module.get<VehiclesService>(VehiclesService);
    decoder = module.get<DiagnosticsDecoder>(DiagnosticsDecoder);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('submitScan Security & Decoding', () => {
    it('should throw NotFoundException when User A attempts to submit a scan for User B vehicle (IDOR)', async () => {
      mockVehiclesService.findOne.mockRejectedValue(new NotFoundException());

      await expect(
        service.submitScan('user_a', '5f9f1b9b9b9b9b9b9b9b9b9b', { transportType: 'BLE', protocol: 'CAN', rawPayloads: [] }),
      ).rejects.toThrow(NotFoundException);
      
      expect(mockVehiclesService.findOne).toHaveBeenCalledWith('5f9f1b9b9b9b9b9b9b9b9b9b', 'user_a');
    });

    it('should proceed and decode when user owns the vehicle', async () => {
      mockVehiclesService.findOne.mockResolvedValue({});
      
      const result = await service.submitScan('owner_id', '5f9f1b9b9b9b9b9b9b9b9b9b', { transportType: 'BLE', protocol: 'CAN', rawPayloads: ['43 01 33 00 00'] });
      
      expect(result).toBeDefined();
      expect(mockVehiclesService.findOne).toHaveBeenCalledWith('5f9f1b9b9b9b9b9b9b9b9b9b', 'owner_id');
      expect((result as any).faults.length).toBe(1);
      expect((result as any).faults[0].code).toBe('P0133');
    });
  });

  describe('getScansForVehicle Security', () => {
    it('should throw NotFoundException when User A attempts to read User B diagnostic scans (IDOR)', async () => {
      mockVehiclesService.findOne.mockRejectedValue(new NotFoundException());

      await expect(service.getScansForVehicle('user_a', '5f9f1b9b9b9b9b9b9b9b9b9b')).rejects.toThrow(NotFoundException);
    });
  });

  describe('clearDtcs Security & Safety', () => {
    it('should throw NotFoundException when User A attempts to clear User B DTCs (IDOR)', async () => {
      mockVehiclesService.findOne.mockRejectedValue(new NotFoundException());

      await expect(service.clearDtcs('user_a', '5f9f1b9b9b9b9b9b9b9b9b9b', 'BLE', 'CAN', '41 0D 00', '44')).rejects.toThrow(NotFoundException);
    });

    it('should throw BadRequestException when vehicle is moving', async () => {
      mockVehiclesService.findOne.mockResolvedValue({});

      await expect(service.clearDtcs('owner_id', '5f9f1b9b9b9b9b9b9b9b9b9b', 'BLE', 'CAN', '41 0D 10', '44')).rejects.toThrow(BadRequestException);
    });

    it('should throw BadRequestException when ECU does not positively acknowledge clear', async () => {
      mockVehiclesService.findOne.mockResolvedValue({});

      await expect(service.clearDtcs('owner_id', '5f9f1b9b9b9b9b9b9b9b9b9b', 'BLE', 'CAN', '41 0D 00', '7F 04 22')).rejects.toThrow(BadRequestException);
    });

    it('should clear successfully when stationary and acknowledged', async () => {
      mockVehiclesService.findOne.mockResolvedValue({});

      const result = await service.clearDtcs('owner_id', '5f9f1b9b9b9b9b9b9b9b9b9b', 'BLE', 'CAN', '41 0D 00', '44');
      expect(result).toBeDefined();
      expect((result as any).isClearCommand).toBe(true);
    });
  });
});
