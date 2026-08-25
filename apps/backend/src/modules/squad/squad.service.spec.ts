import { Test, TestingModule } from '@nestjs/testing';
import { getModelToken } from '@nestjs/mongoose';
import { SquadService } from './squad.service';
import { SquadRoom } from './schemas/squad-room.schema';
import { RidersService } from '../riders/riders.service';

describe('SquadService', () => {
  let service: SquadService;

  const mockSquadModel = function (dto: any) {
    this._id = 'squad-123';
    this.squadCode = dto.squadCode;
    this.title = dto.title;
    this.creatorId = dto.creatorId;
    this.members = dto.members || [];
    this.save = jest.fn().mockResolvedValue(this);
  };
  mockSquadModel.findOne = jest.fn();
  mockSquadModel.findById = jest.fn();

  const mockRidersService = {
    findById: jest.fn().mockResolvedValue({
      _id: 'rider-123',
      fullName: 'Jane Rider',
    }),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SquadService,
        { provide: getModelToken(SquadRoom.name), useValue: mockSquadModel },
        { provide: RidersService, useValue: mockRidersService },
      ],
    }).compile();

    service = module.get<SquadService>(SquadService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should create squad room with 6-character code', async () => {
    const result = await service.createSquad('rider-123', { title: 'Weekend Canyon Run' });
    expect(result).toBeDefined();
    expect(result.squadCode).toHaveLength(6);
    expect(result.title).toEqual('Weekend Canyon Run');
  });
});
