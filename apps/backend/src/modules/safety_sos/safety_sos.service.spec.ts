import { Test, TestingModule } from '@nestjs/testing';
import { getModelToken } from '@nestjs/mongoose';
import { SafetySosService } from './safety_sos.service';
import { SosIncident } from './schemas/sos-incident.schema';
import { EmergencyDispatcherService } from './services/emergency-dispatcher.service';
import { RidersService } from '../riders/riders.service';

describe('SafetySosService', () => {
  let service: SafetySosService;

  const mockSosModel = function (dto: any) {
    this._id = 'sos-incident-123';
    this.riderId = dto.riderId;
    this.status = dto.status;
    this.save = jest.fn().mockResolvedValue(this);
  };
  mockSosModel.findOne = jest.fn();
  mockSosModel.find = jest.fn().mockReturnValue({
    sort: jest.fn().mockReturnValue({
      exec: jest.fn().mockResolvedValue([]),
    }),
  });

  const mockDispatcher = {
    dispatchEmergencyAlert: jest.fn().mockResolvedValue({ dispatchedContactsCount: 1 }),
  };

  const mockRidersService = {
    findById: jest.fn().mockResolvedValue({
      emergencyContacts: [{ name: 'John Doe', phone: '+1234567890' }],
    }),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SafetySosService,
        { provide: getModelToken(SosIncident.name), useValue: mockSosModel },
        { provide: EmergencyDispatcherService, useValue: mockDispatcher },
        { provide: RidersService, useValue: mockRidersService },
      ],
    }).compile();

    service = module.get<SafetySosService>(SafetySosService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should trigger emergency SOS incident', async () => {
    const result = await service.triggerSos('rider-123', {
      lat: 37.7749,
      lng: -122.4194,
      triggerType: 'AUTOMATIC_IMPACT',
      impactForceG: 5.4,
    });

    expect(result).toBeDefined();
    expect(result.status).toEqual('DISPATCHED');
  });
});
