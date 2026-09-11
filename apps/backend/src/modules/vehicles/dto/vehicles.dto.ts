import { IsString, IsOptional, IsNumber, IsBoolean, MaxLength, MinLength } from 'class-validator';

export class CreateVehicleDto {
  @IsString()
  @IsOptional()
  masterVehicleId?: string;

  @IsString()
  category: string;

  @IsString()
  manufacturer: string;

  @IsString()
  model: string;

  @IsString()
  @IsOptional()
  variant?: string;

  @IsNumber()
  year: number;

  @IsString()
  @IsOptional()
  @MinLength(17)
  @MaxLength(17)
  vin?: string;

  @IsString()
  @IsOptional()
  registrationNumber?: string;

  @IsString()
  fuelType: string;

  @IsString()
  @IsOptional()
  powertrainType?: string;

  @IsNumber()
  @IsOptional()
  engineCc?: number;

  @IsString()
  @IsOptional()
  transmission?: string;

  @IsNumber()
  @IsOptional()
  batteryCapacityKwh?: number;

  @IsNumber()
  @IsOptional()
  rangeKm?: number;

  @IsString()
  @IsOptional()
  chargingType?: string;

  @IsString()
  @IsOptional()
  color?: string;

  @IsString()
  @IsOptional()
  nickname?: string;

  @IsNumber()
  @IsOptional()
  odometer?: number;
}

export class UpdateVehicleDto extends CreateVehicleDto {
  @IsBoolean()
  @IsOptional()
  isActive?: boolean;

  @IsBoolean()
  @IsOptional()
  isPrimary?: boolean;
}
