import { IsString, IsNotEmpty, IsNumber, IsOptional, IsArray, IsEnum, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

export enum SyncDataSource {
  REAL_DEVICE = 'REAL_DEVICE',
  BENCH_TEST = 'BENCH_TEST',
  SIMULATED = 'SIMULATED',
}

export class SyncDtcItemDto {
  @IsString()
  @IsNotEmpty()
  code: string;

  @IsString()
  @IsNotEmpty()
  subsystem: string;

  @IsString()
  @IsNotEmpty()
  description: string;

  @IsString()
  @IsNotEmpty()
  severity: string;

  @IsString()
  @IsNotEmpty()
  detectedAt: string;
}

export class SyncRideSessionPayloadDto {
  @IsString()
  @IsNotEmpty()
  sessionId: string;

  @IsString()
  @IsNotEmpty()
  riderId: string;

  @IsString()
  @IsOptional()
  vehicleProfileId?: string;

  @IsString()
  @IsNotEmpty()
  startTime: string;

  @IsString()
  @IsNotEmpty()
  endTime: string;

  @IsNumber()
  totalDistanceKm: number;

  @IsNumber()
  durationMinutes: number;

  @IsNumber()
  maxSpeedKmh: number;

  @IsNumber()
  averageSpeedKmh: number;

  @IsNumber()
  maxRpm: number;

  @IsNumber()
  averageRpm: number;

  @IsNumber()
  maxLeanAngleDeg: number;

  @IsNumber()
  @IsOptional()
  batteryMinVoltage?: number = 12.6;

  @IsNumber()
  @IsOptional()
  batteryMaxVoltage?: number = 14.2;

  @IsNumber()
  @IsOptional()
  totalPacketsReceived?: number = 100;

  @IsNumber()
  @IsOptional()
  packetLossPercentage?: number = 0.0;

  @IsEnum(SyncDataSource)
  @IsOptional()
  dataSource?: SyncDataSource = SyncDataSource.REAL_DEVICE;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SyncDtcItemDto)
  @IsOptional()
  detectedDtcs?: SyncDtcItemDto[] = [];
}
