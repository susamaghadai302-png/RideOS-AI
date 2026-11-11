import { IsString, IsNotEmpty, IsOptional, IsIn, IsBoolean, IsNumber } from 'class-validator';

export class CreateMemoryDto {
  @IsString()
  @IsNotEmpty()
  key: string;

  @IsString()
  @IsNotEmpty()
  value: string;

  @IsOptional()
  @IsIn(['RIDING_STYLE', 'VEHICLE_PREF', 'ROUTE_PREF', 'SAFETY_NOTE', 'GENERAL'])
  category?: 'RIDING_STYLE' | 'VEHICLE_PREF' | 'ROUTE_PREF' | 'SAFETY_NOTE' | 'GENERAL';

  @IsOptional()
  @IsIn(['USER_EXPLICIT', 'INFERRED', 'VEHICLE_LOG'])
  source?: 'USER_EXPLICIT' | 'INFERRED' | 'VEHICLE_LOG';

  @IsOptional()
  @IsBoolean()
  isConsentGranted?: boolean;

  @IsOptional()
  @IsNumber()
  retentionDays?: number;
}

export class UpdateMemoryDto {
  @IsOptional()
  @IsString()
  value?: string;

  @IsOptional()
  @IsIn(['RIDING_STYLE', 'VEHICLE_PREF', 'ROUTE_PREF', 'SAFETY_NOTE', 'GENERAL'])
  category?: 'RIDING_STYLE' | 'VEHICLE_PREF' | 'ROUTE_PREF' | 'SAFETY_NOTE' | 'GENERAL';

  @IsOptional()
  @IsBoolean()
  isConsentGranted?: boolean;
}

