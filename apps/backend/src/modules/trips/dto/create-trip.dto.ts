import { IsString, IsNotEmpty, IsOptional, IsNumber, IsEnum, IsArray, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { TripStatus } from '../schemas/trip.schema';

export class LocationPointDto {
  @IsNumber()
  lat: number;

  @IsNumber()
  lng: number;

  @IsOptional()
  @IsNumber()
  altitude?: number;

  @IsOptional()
  @IsNumber()
  speedKmh?: number;

  @IsOptional()
  @IsNumber()
  accuracyMeters?: number;

  @IsOptional()
  timestamp?: Date;

  @IsOptional()
  @IsString()
  address?: string;
}

export class TripEventDto {
  @IsString()
  @IsNotEmpty()
  eventType: string;

  @IsOptional()
  timestamp?: Date;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsNumber()
  lat?: number;

  @IsOptional()
  @IsNumber()
  lng?: number;
}

export class CreateTripDto {
  @IsString()
  @IsNotEmpty()
  tripId: string;

  @IsString()
  @IsNotEmpty()
  vehicleId: string;

  @IsOptional()
  @IsString()
  title?: string;

  @IsOptional()
  @IsEnum(TripStatus)
  status?: TripStatus;

  @IsOptional()
  startTime?: Date;

  @IsOptional()
  endTime?: Date;

  @IsOptional()
  @IsNumber()
  distanceKm?: number;

  @IsOptional()
  @IsNumber()
  durationSeconds?: number;

  @IsOptional()
  @IsNumber()
  avgSpeedKmh?: number;

  @IsOptional()
  @IsNumber()
  maxSpeedKmh?: number;

  @IsOptional()
  @ValidateNested()
  @Type(() => LocationPointDto)
  startLocation?: LocationPointDto;

  @IsOptional()
  @ValidateNested()
  @Type(() => LocationPointDto)
  endLocation?: LocationPointDto;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => LocationPointDto)
  routeCoordinates?: LocationPointDto[];

  @IsOptional()
  @IsNumber()
  fuelConsumedLiters?: number;

  @IsOptional()
  @IsNumber()
  batteryConsumedPct?: number;

  @IsOptional()
  @IsString()
  gpsSource?: string;

  @IsOptional()
  @IsString()
  telemetrySource?: string;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => TripEventDto)
  events?: TripEventDto[];
}

export class AddTripPointsDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => LocationPointDto)
  points: LocationPointDto[];
}

export class FinishTripDto {
  @IsOptional()
  endTime?: Date;

  @IsOptional()
  @IsNumber()
  distanceKm?: number;

  @IsOptional()
  @IsNumber()
  durationSeconds?: number;

  @IsOptional()
  @IsNumber()
  avgSpeedKmh?: number;

  @IsOptional()
  @IsNumber()
  maxSpeedKmh?: number;

  @IsOptional()
  @ValidateNested()
  @Type(() => LocationPointDto)
  endLocation?: LocationPointDto;

  @IsOptional()
  @IsNumber()
  fuelConsumedLiters?: number;

  @IsOptional()
  @IsNumber()
  batteryConsumedPct?: number;
}

export class CreateSavedPlaceDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsNotEmpty()
  category: string;

  @IsNumber()
  lat: number;

  @IsNumber()
  lng: number;

  @IsOptional()
  @IsString()
  address?: string;

  @IsOptional()
  @IsString()
  icon?: string;
}
