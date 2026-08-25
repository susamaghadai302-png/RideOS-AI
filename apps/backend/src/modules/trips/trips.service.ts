import { Injectable, NotFoundException, ForbiddenException, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Trip, TripDocument, TripStatus } from './schemas/trip.schema';
import { CreateTripDto, FinishTripDto, LocationPointDto, TripEventDto } from './dto/create-trip.dto';

@Injectable()
export class TripsService {
  private readonly logger = new Logger(TripsService.name);

  constructor(
    @InjectModel(Trip.name) private readonly tripModel: Model<TripDocument>,
  ) {}

  /**
   * Create or Sync a complete Trip record (supports offline batch sync from mobile)
   */
  async createOrSyncTrip(riderId: string, dto: CreateTripDto): Promise<TripDocument> {
    const existing = await this.tripModel.findOne({ tripId: dto.tripId }).exec();

    if (existing) {
      if (existing.riderId !== riderId) {
        throw new ForbiddenException('Unauthorized access to this trip record');
      }

      existing.title = dto.title || existing.title;
      existing.status = dto.status || existing.status;
      existing.distanceKm = dto.distanceKm !== undefined ? dto.distanceKm : existing.distanceKm;
      existing.durationSeconds = dto.durationSeconds !== undefined ? dto.durationSeconds : existing.durationSeconds;
      existing.avgSpeedKmh = dto.avgSpeedKmh !== undefined ? dto.avgSpeedKmh : existing.avgSpeedKmh;
      existing.maxSpeedKmh = dto.maxSpeedKmh !== undefined ? dto.maxSpeedKmh : existing.maxSpeedKmh;
      existing.startLocation = dto.startLocation || existing.startLocation;
      existing.endLocation = dto.endLocation || existing.endLocation;
      existing.fuelConsumedLiters = dto.fuelConsumedLiters || existing.fuelConsumedLiters;
      existing.batteryConsumedPct = dto.batteryConsumedPct || existing.batteryConsumedPct;
      existing.gpsSource = dto.gpsSource || existing.gpsSource;
      existing.telemetrySource = dto.telemetrySource || existing.telemetrySource;

      if (dto.routeCoordinates && dto.routeCoordinates.length > 0) {
        existing.routeCoordinates = dto.routeCoordinates as any;
      }
      if (dto.events && dto.events.length > 0) {
        existing.events = dto.events as any;
      }

      return existing.save();
    }

    const newTrip = new this.tripModel({
      ...dto,
      riderId,
      startTime: dto.startTime || new Date(),
    });

    return newTrip.save();
  }

  /**
   * Start a new live trip
   */
  async startTrip(riderId: string, tripId: string, vehicleId: string, startLocation?: LocationPointDto): Promise<TripDocument> {
    const trip = new this.tripModel({
      tripId,
      riderId,
      vehicleId,
      status: TripStatus.ACTIVE,
      startTime: new Date(),
      startLocation,
      routeCoordinates: startLocation ? [startLocation] : [],
      events: [
        {
          eventType: 'TRIP_STARTED',
          timestamp: new Date(),
          description: 'Live trip recording started',
          lat: startLocation?.lat,
          lng: startLocation?.lng,
        },
      ],
    });

    return trip.save();
  }

  /**
   * Complete an active trip
   */
  async finishTrip(riderId: string, tripId: string, dto: FinishTripDto): Promise<TripDocument> {
    const trip = await this.tripModel.findOne({ tripId }).exec();
    if (!trip) {
      throw new NotFoundException(`Trip ${tripId} not found`);
    }
    if (trip.riderId !== riderId) {
      throw new ForbiddenException('Unauthorized access to this trip');
    }

    trip.status = TripStatus.COMPLETED;
    trip.endTime = dto.endTime || new Date();
    if (dto.distanceKm !== undefined) trip.distanceKm = dto.distanceKm;
    if (dto.durationSeconds !== undefined) trip.durationSeconds = dto.durationSeconds;
    if (dto.avgSpeedKmh !== undefined) trip.avgSpeedKmh = dto.avgSpeedKmh;
    if (dto.maxSpeedKmh !== undefined) trip.maxSpeedKmh = dto.maxSpeedKmh;
    if (dto.endLocation) trip.endLocation = dto.endLocation as any;
    if (dto.fuelConsumedLiters !== undefined) trip.fuelConsumedLiters = dto.fuelConsumedLiters;
    if (dto.batteryConsumedPct !== undefined) trip.batteryConsumedPct = dto.batteryConsumedPct;

    trip.events.push({
      eventType: 'TRIP_COMPLETED',
      timestamp: new Date(),
      description: 'Trip arrived and finalized',
      lat: dto.endLocation?.lat,
      lng: dto.endLocation?.lng,
    });

    return trip.save();
  }

  /**
   * Append buffered location samples to an ongoing trip
   */
  async addTripPoints(riderId: string, tripId: string, points: LocationPointDto[]): Promise<void> {
    if (!points || points.length === 0) return;

    const trip = await this.tripModel.findOne({ tripId }).exec();
    if (!trip) {
      throw new NotFoundException(`Trip ${tripId} not found`);
    }
    if (trip.riderId !== riderId) {
      throw new ForbiddenException('Unauthorized access to this trip');
    }

    trip.routeCoordinates.push(...(points as any));

    // Update max speed from incoming points
    for (const pt of points) {
      if (pt.speedKmh && pt.speedKmh > trip.maxSpeedKmh) {
        trip.maxSpeedKmh = Math.round(pt.speedKmh * 10) / 10;
      }
    }

    await trip.save();
  }

  /**
   * Record hardware, safety, or connectivity events during a ride
   */
  async recordTripEvent(riderId: string, tripId: string, event: TripEventDto): Promise<void> {
    const trip = await this.tripModel.findOne({ tripId }).exec();
    if (!trip) {
      throw new NotFoundException(`Trip ${tripId} not found`);
    }
    if (trip.riderId !== riderId) {
      throw new ForbiddenException('Unauthorized access to this trip');
    }

    trip.events.push({
      eventType: event.eventType,
      timestamp: event.timestamp || new Date(),
      description: event.description,
      lat: event.lat,
      lng: event.lng,
    });

    await trip.save();
  }

  /**
   * Get user's trips with pagination
   */
  async getUserTrips(riderId: string, limit: number = 20, skip: number = 0): Promise<{ trips: TripDocument[]; total: number }> {
    const [trips, total] = await Promise.all([
      this.tripModel
        .find({ riderId })
        .sort({ startTime: -1 })
        .skip(skip)
        .limit(limit)
        .select('-routeCoordinates') // Exclude heavy polyline points for lightweight list view
        .exec(),
      this.tripModel.countDocuments({ riderId }).exec(),
    ]);

    return { trips, total };
  }

  /**
   * Get detailed single trip with all polyline coordinates and events
   */
  async getTripById(riderId: string, tripId: string): Promise<TripDocument> {
    const trip = await this.tripModel.findOne({ tripId }).exec();
    if (!trip) {
      throw new NotFoundException(`Trip with ID ${tripId} not found`);
    }
    if (trip.riderId !== riderId) {
      throw new ForbiddenException('Unauthorized access to this trip');
    }
    return trip;
  }

  /**
   * Delete a trip record securely
   */
  async deleteTrip(riderId: string, tripId: string): Promise<{ deleted: boolean }> {
    const trip = await this.tripModel.findOne({ tripId }).exec();
    if (!trip) {
      throw new NotFoundException(`Trip ${tripId} not found`);
    }
    if (trip.riderId !== riderId) {
      throw new ForbiddenException('Unauthorized access to this trip');
    }

    await this.tripModel.deleteOne({ tripId }).exec();
    return { deleted: true };
  }
}
