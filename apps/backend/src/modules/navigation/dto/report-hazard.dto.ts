import { IsEnum, IsString, IsOptional, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { GeoPointDto } from './calculate-route.dto';

export class ReportHazardDto {
  @IsEnum(['GRAVEL', 'OIL', 'ACCIDENT', 'CONSTRUCTION', 'POLICE'])
  type: 'GRAVEL' | 'OIL' | 'ACCIDENT' | 'CONSTRUCTION' | 'POLICE';

  @IsEnum(['LOW', 'MEDIUM', 'HIGH'])
  severity: 'LOW' | 'MEDIUM' | 'HIGH';

  @ValidateNested()
  @Type(() => GeoPointDto)
  location: GeoPointDto;

  @IsString()
  @IsOptional()
  description?: string;
}
