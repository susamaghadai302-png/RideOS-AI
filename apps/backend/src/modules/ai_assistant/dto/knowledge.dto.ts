import { IsString, IsNotEmpty, IsOptional, IsIn, IsArray, IsBoolean } from 'class-validator';

export class CreateKnowledgeDto {
  @IsString()
  @IsNotEmpty()
  vehicleModel: string;

  @IsString()
  @IsNotEmpty()
  title: string;

  @IsOptional()
  @IsIn(['MANUAL', 'SPECS', 'MAINTENANCE', 'SAFETY'])
  category?: 'MANUAL' | 'SPECS' | 'MAINTENANCE' | 'SAFETY';

  @IsString()
  @IsNotEmpty()
  content: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  tags?: string[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  citations?: string[];

  @IsOptional()
  @IsBoolean()
  isVerified?: boolean;
}

export class QueryKnowledgeDto {
  @IsString()
  @IsNotEmpty()
  query: string;

  @IsOptional()
  @IsString()
  vehicleModel?: string;
}

