import { IsString, IsNumber, IsOptional, IsEnum, IsArray, ValidateNested } from 'class-validator';

export class ReconstructDigitalTwinDto {
  @IsString()
  vehicleId: string;

  @IsString()
  manufacturer: string;

  @IsString()
  model: string;

  @IsOptional()
  @IsString()
  variant?: string;

  @IsNumber()
  year: number;

  @IsOptional()
  @IsString()
  category?: string;

  @IsOptional()
  @IsString()
  targetQuality?: 'LOW' | 'MEDIUM' | 'HIGH' | 'ULTRA';

  @IsNumber()
  frameCount: number;

  @IsOptional()
  @IsString()
  dominantColorHex?: string;
}

export class SaveDigitalTwinDto {
  @IsString()
  twinId: string;

  @IsString()
  vehicleId: string;

  @IsString()
  riderId: string;

  @IsString()
  manufacturer: string;

  @IsString()
  model: string;

  @IsOptional()
  @IsString()
  variant?: string;

  @IsNumber()
  year: number;

  @IsOptional()
  @IsString()
  category?: string;

  @IsString()
  modelGlbPath: string;

  @IsString()
  thumbnailUrl: string;

  @IsString()
  quality: string;

  @IsNumber()
  scanCoveragePercent: number;

  @IsNumber()
  sourceImageCount: number;

  @IsOptional()
  meshStats?: {
    polygonCount: number;
    vertexCount: number;
    lengthMeters: number;
    widthMeters: number;
    heightMeters: number;
    isGroundAligned: boolean;
  };

  @IsOptional()
  @IsArray()
  componentHotspots?: Array<{ name: string; pos: number[] }>;
}
