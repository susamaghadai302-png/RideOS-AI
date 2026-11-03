import { IsNumber, IsOptional, IsArray, ValidateNested, IsEnum, Min, Max, ArrayMaxSize } from 'class-validator';
import { Type } from 'class-transformer';

export class GeoPointDto {
  @IsNumber()
  @Min(-90)
  @Max(90)
  lat: number;

  @IsNumber()
  @Min(-180)
  @Max(180)
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
  @ArrayMaxSize(25)
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
