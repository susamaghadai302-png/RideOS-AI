import { IsNumber, IsOptional, IsArray, ValidateNested, IsEnum, IsString } from 'class-validator';
import { Type } from 'class-transformer';

export class GeoPointDto {
  @IsNumber()
  lat: number;

  @IsNumber()
  lng: number;
}

export class CalculateRouteDto {
  @ValidateNested()
  @Type(() => GeoPointDto)
  origin: GeoPointDto;

  @ValidateNested()
  @Type(() => GeoPointDto)
  destination: GeoPointDto;

  @IsArray()
  @IsOptional()
  @ValidateNested({ each: true })
  @Type(() => GeoPointDto)
  waypoints?: GeoPointDto[];

  @IsEnum(['SCENIC_TWISTY', 'FASTEST', 'AVOID_HIGHWAYS', 'MOTORCYCLE_CUSTOM'])
  @IsOptional()
  preference?: 'SCENIC_TWISTY' | 'FASTEST' | 'AVOID_HIGHWAYS' | 'MOTORCYCLE_CUSTOM';

  @IsEnum(['OSRM', 'MAPBOX', 'GOOGLE_MAPS'])
  @IsOptional()
  provider?: 'OSRM' | 'MAPBOX' | 'GOOGLE_MAPS';
}
