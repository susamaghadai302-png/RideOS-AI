import { IsString, IsBoolean, IsNumber, IsOptional, IsEnum } from 'class-validator';

export class UpdatePreferencesDto {
  @IsEnum(['SCENIC_TWISTY', 'FASTEST', 'AVOID_HIGHWAYS'])
  @IsOptional()
  routingPreference?: 'SCENIC_TWISTY' | 'FASTEST' | 'AVOID_HIGHWAYS';

  @IsBoolean()
  @IsOptional()
  voiceAlertsEnabled?: boolean;

  @IsNumber()
  @IsOptional()
  sosAutoDispatchDelaySeconds?: number;

  @IsEnum(['METRIC', 'IMPERIAL'])
  @IsOptional()
  units?: 'METRIC' | 'IMPERIAL';
}
