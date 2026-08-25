import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type TripDocument = Trip & Document;

export enum TripStatus {
  IDLE = 'IDLE',
  READY = 'READY',
  ACTIVE = 'ACTIVE',
  PAUSED = 'PAUSED',
  COMPLETED = 'COMPLETED',
  CANCELLED = 'CANCELLED',
}

@Schema({ _id: false })
export class LocationPoint {
  @Prop({ required: true })
  lat: number;

  @Prop({ required: true })
  lng: number;

  @Prop()
  altitude?: number;

  @Prop()
  speedKmh?: number;

  @Prop()
  accuracyMeters?: number;

  @Prop()
  timestamp?: Date;

  @Prop()
  address?: string;
}

@Schema({ _id: false })
export class TripEventItem {
  @Prop({ required: true })
  eventType: string; // 'BLUETOOTH_DISCONNECT', 'BLUETOOTH_RECONNECT', 'GPS_SIGNAL_LOST', 'HARD_BRAKE', 'MAX_LEAN'

  @Prop({ required: true, default: Date.now })
  timestamp: Date;

  @Prop()
  description?: string;

  @Prop()
  lat?: number;

  @Prop()
  lng?: number;
}

@Schema({ timestamps: true })
export class Trip {
  @Prop({ required: true, unique: true, index: true })
  tripId: string;

  @Prop({ required: true, index: true })
  riderId: string;

  @Prop({ required: true, index: true })
  vehicleId: string;

  @Prop({ default: 'Motorcycle Journey' })
  title: string;

  @Prop({ type: String, enum: TripStatus, default: TripStatus.ACTIVE, index: true })
  status: TripStatus;

  @Prop({ required: true, default: Date.now })
  startTime: Date;

  @Prop()
  endTime?: Date;

  @Prop({ default: 0 })
  distanceKm: number;

  @Prop({ default: 0 })
  durationSeconds: number;

  @Prop({ default: 0 })
  avgSpeedKmh: number;

  @Prop({ default: 0 })
  maxSpeedKmh: number;

  @Prop({ type: LocationPoint })
  startLocation?: LocationPoint;

  @Prop({ type: LocationPoint })
  endLocation?: LocationPoint;

  @Prop({ type: [LocationPoint], default: [] })
  routeCoordinates: LocationPoint[];

  @Prop()
  fuelConsumedLiters?: number;

  @Prop()
  batteryConsumedPct?: number;

  @Prop({ default: 'PHONE_GPS' })
  gpsSource: string; // 'VEHICLE_GPS' | 'PHONE_GPS' | 'HYBRID'

  @Prop({ default: 'BLUETOOTH_BLE' })
  telemetrySource: string;

  @Prop({ type: [TripEventItem], default: [] })
  events: TripEventItem[];
}

export const TripSchema = SchemaFactory.createForClass(Trip);

// Performance Compound Indexes
TripSchema.index({ riderId: 1, startTime: -1 });
TripSchema.index({ vehicleId: 1, startTime: -1 });
