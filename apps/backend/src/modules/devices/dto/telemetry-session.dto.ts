import { IsString, IsNotEmpty, IsOptional, IsNumber, IsBoolean } from 'class-validator';

export class StartTelemetrySessionDto {
  @IsString()
  @IsNotEmpty()
  deviceId: string;

  @IsString()
  @IsOptional()
  vehicleProfileId?: string;

}

export class StopTelemetrySessionDto {
  @IsNumber()
  @IsOptional()
  totalSamplesRecorded?: number;

  @IsNumber()
  @IsOptional()
  totalDistanceKm?: number;

  @IsNumber()
  @IsOptional()
  averageSpeedKmh?: number;

  @IsNumber()
  @IsOptional()
  maxSpeedKmh?: number;

  @IsNumber()
  @IsOptional()
  packetLossPercentage?: number;
}
