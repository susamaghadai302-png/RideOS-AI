import { Test, TestingModule } from '@nestjs/testing';
import { VehiclesService } from './vehicles.service';
import { getModelToken } from '@nestjs/mongoose';
import { UserVehicle } from './schemas/user-vehicle.schema';

const mockVehicle = {
  _id: '123',
  ownerId: 'user1',
  category: 'Car',
  manufacturer: 'Tesla',
  model: 'Model 3',
  year: 2024,
  fuelType: 'Electric',
  isActive: true,
  isPrimary: true,
  save: jest.fn().mockResolvedValue(this),
};

describe('VehiclesService', () => {
  let service: VehiclesService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        VehiclesService,
        {
          provide: getModelToken(UserVehicle.name),
          useValue: {
            new: jest.fn().mockResolvedValue(mockVehicle),
            constructor: jest.fn().mockResolvedValue(mockVehicle),
            find: jest.fn(),
            findOne: jest.fn(),
            countDocuments: jest.fn(),
            updateMany: jest.fn(),
            exec: jest.fn(),
            create: jest.fn().mockResolvedValue(mockVehicle),
          },
        },
      ],
    }).compile();

    service = module.get<VehiclesService>(VehiclesService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
