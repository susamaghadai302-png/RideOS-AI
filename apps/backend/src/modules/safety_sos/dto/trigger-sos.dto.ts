import { IsString, IsNumber, IsEnum, IsOptional } from 'class-validator';

export class TriggerSosDto {
  @IsNumber()
  lat: number;

  @IsNumber()
  lng: number;

  @IsEnum(['MANUAL', 'AUTOMATIC_IMPACT', 'FALL_DETECTION'])
  triggerType: 'MANUAL' | 'AUTOMATIC_IMPACT' | 'FALL_DETECTION';

  @IsNumber()
  @IsOptional()
  impactForceG?: number;

  @IsString()
  @IsOptional()
  tripId?: string;
}
