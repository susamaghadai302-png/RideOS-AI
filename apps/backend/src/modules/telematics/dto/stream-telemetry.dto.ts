import { IsString, IsNumber, IsOptional, IsDateString } from 'class-validator';

export class StreamTelemetryDto {
  @IsString()
  tripId: string;

  @IsDateString()
  timestamp: string;

  @IsNumber()
  lat: number;

  @IsNumber()
  lng: number;

  @IsNumber()
  speedKmh: number;

  @IsNumber()
  leanAngle: number;

  @IsNumber()
  accelG: number;

  @IsNumber()
  @IsOptional()
  elevationM?: number;

  @IsNumber()
  @IsOptional()
  batteryLevel?: number;
}
