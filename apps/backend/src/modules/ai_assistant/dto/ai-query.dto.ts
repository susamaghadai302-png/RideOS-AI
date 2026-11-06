import { IsString, IsOptional, ValidateNested, IsBoolean, IsNumber, IsIn } from 'class-validator';
import { Type } from 'class-transformer';

export class RiderContextDto {
  @IsOptional()
  @IsNumber()
  currentLat?: number;

  @IsOptional()
  @IsNumber()
  currentLng?: number;

  @IsOptional()
  @IsNumber()
  speedKmh?: number;

  @IsOptional()
  @IsString()
  bikeMake?: string;

  @IsOptional()
  @IsString()
  bikeModel?: string;

  @IsOptional()
  @IsString()
  riderName?: string;
}

export class TelemetryContextDto {
  @IsOptional()
  @IsNumber()
  speedKmh?: number;

  @IsOptional()
  @IsNumber()
  engineRpm?: number;

  @IsOptional()
  @IsNumber()
  batteryVoltage?: number;

  @IsOptional()
  @IsNumber()
  coolantTempC?: number;

  @IsOptional()
  @IsNumber()
  fuelLevelPct?: number;

  @IsOptional()
  @IsNumber()
  leanAngleDeg?: number;

  @IsOptional()
  @IsBoolean()
  isSimulated?: boolean;
}

export class AiQueryDto {
  @IsString()
  prompt: string;

  @IsOptional()
  @IsString()
  conversationId?: string;

  @IsOptional()
  @IsIn(['en', 'hi', 'hinglish', 'or'])
  language?: 'en' | 'hi' | 'hinglish' | 'or';

  @IsOptional()
  @IsBoolean()
  includeMemories?: boolean;

  @IsOptional()
  @ValidateNested()
  @Type(() => RiderContextDto)
  riderContext?: RiderContextDto;

  @IsOptional()
  @ValidateNested()
  @Type(() => TelemetryContextDto)
  telemetryContext?: TelemetryContextDto;
}
