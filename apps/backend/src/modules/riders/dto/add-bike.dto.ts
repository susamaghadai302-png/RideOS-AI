import { IsString, IsNumber, IsOptional, IsBoolean } from 'class-validator';

export class AddBikeDto {
  @IsString()
  make: string;

  @IsString()
  model: string;

  @IsNumber()
  year: number;

  @IsNumber()
  engineCC: number;

  @IsNumber()
  @IsOptional()
  maxLeanAngleLimit?: number;

  @IsBoolean()
  @IsOptional()
  isPrimary?: boolean;
}
