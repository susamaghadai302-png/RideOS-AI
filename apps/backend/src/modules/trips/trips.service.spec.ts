import { Test, TestingModule } from '@nestjs/testing';
import { getModelToken } from '@nestjs/mongoose';
import { TripsService } from './trips.service';
import { Trip, TripStatus } from './schemas/trip.schema';
import { ForbiddenException, NotFoundException } from '@nestjs/common';

describe('TripsService Unit Tests', () => {
  let service: TripsService;
  let mockTripModel: any;

  const mockTripDocument = {
    tripId: 'trip-abc-123',
    riderId: 'rider-001',
    vehicleId: 'veh-yamaha-r1',
    title: 'Canyon Run',
    status: TripStatus.ACTIVE,
    startTime: new Date(),
    distanceKm: 24.5,
    durationSeconds: 1200,
    avgSpeedKmh: 73.5,
    maxSpeedKmh: 142.0,
    routeCoordinates: [
      { lat: 34.0522, lng: -118.2437, speedKmh: 65.0 },
    ],
    events: [],
    save: jest.fn().mockResolvedValue(this),
  };

  beforeEach(async () => {
    mockTripModel = jest.fn().mockImplementation((dto) => ({
      ...dto,
      save: jest.fn().mockResolvedValue({ ...dto, _id: 'mongo-id-123' }),
    }));

    mockTripModel.findOne = jest.fn();
    mockTripModel.find = jest.fn();
    mockTripModel.countDocuments = jest.fn();
    mockTripModel.deleteOne = jest.fn();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TripsService,
        {
          provide: getModelToken(Trip.name),
          useValue: mockTripModel,
        },
      ],
    }).compile();

    service = module.get<TripsService>(TripsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('startTrip', () => {
    it('should create and start a new live trip', async () => {
      const result = await service.startTrip('rider-001', 'trip-999', 'veh-ducati', {
        lat: 37.7749,
        lng: -122.4194,
      });

      expect(result).toBeDefined();
      expect(result.tripId).toBe('trip-999');
      expect(result.status).toBe(TripStatus.ACTIVE);
      expect(result.events.length).toBeGreaterThan(0);
      expect(result.events[0].eventType).toBe('TRIP_STARTED');
    });
  });

  describe('finishTrip', () => {
    it('should finalize an active trip and update statistics', async () => {
      const activeTrip = {
        ...mockTripDocument,
        save: jest.fn().mockResolvedValue({
          ...mockTripDocument,
          status: TripStatus.COMPLETED,
          distanceKm: 32.4,
        }),
      };
      mockTripModel.findOne.mockReturnValue({
        exec: jest.fn().mockResolvedValue(activeTrip),
      });

      const res = await service.finishTrip('rider-001', 'trip-abc-123', {
        distanceKm: 32.4,
        durationSeconds: 1500,
        avgSpeedKmh: 77.8,
        maxSpeedKmh: 148.0,
      });

      expect(res.status).toBe(TripStatus.COMPLETED);
      expect(activeTrip.save).toHaveBeenCalled();
    });

    it('should throw ForbiddenException if user does not own the trip', async () => {
      mockTripModel.findOne.mockReturnValue({
        exec: jest.fn().mockResolvedValue(mockTripDocument),
      });

      await expect(
        service.finishTrip('hacker-user', 'trip-abc-123', {}),
      ).rejects.toThrow(ForbiddenException);
    });

    it('should throw NotFoundException if trip does not exist', async () => {
      mockTripModel.findOne.mockReturnValue({
        exec: jest.fn().mockResolvedValue(null),
      });

      await expect(
        service.finishTrip('rider-001', 'non-existent-trip', {}),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('addTripPoints', () => {
    it('should append location samples and update max speed', async () => {
      const activeTrip = {
        ...mockTripDocument,
        routeCoordinates: [],
        maxSpeedKmh: 100.0,
        save: jest.fn().mockResolvedValue(true),
      };
      mockTripModel.findOne.mockReturnValue({
        exec: jest.fn().mockResolvedValue(activeTrip),
      });

      await service.addTripPoints('rider-001', 'trip-abc-123', [
        { lat: 34.05, lng: -118.25, speedKmh: 135.5 },
      ]);

      expect(activeTrip.routeCoordinates.length).toBe(1);
      expect(activeTrip.maxSpeedKmh).toBe(135.5);
      expect(activeTrip.save).toHaveBeenCalled();
    });
  });
});
