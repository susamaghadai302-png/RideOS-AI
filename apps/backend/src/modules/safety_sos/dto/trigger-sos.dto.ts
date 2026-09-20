import { IsString, IsNumber, IsEnum, IsOptional } from 'class-validator';

export class TriggerSosDto {
  @IsNumber()
  @IsOptional()
  lat?: number;

  @IsNumber()
  @IsOptional()
  lng?: number;

  @IsEnum(['MANUAL', 'AUTOMATIC_IMPACT', 'FALL_DETECTION'])
  triggerType: 'MANUAL' | 'AUTOMATIC_IMPACT' | 'FALL_DETECTION';

  @IsNumber()
  @IsOptional()
  impactForceG?: number;

  @IsString()
  @IsOptional()
  tripId?: string;
}
