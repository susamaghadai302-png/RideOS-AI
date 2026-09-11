import { IsString, IsNotEmpty, IsArray, IsOptional, IsBoolean } from 'class-validator';

export class DiagnosticFaultDto {
  @IsString()
  @IsNotEmpty()
  code: string;

  @IsString()
  @IsNotEmpty()
  module: string;

  @IsString()
  @IsNotEmpty()
  severity: string;
}

export class SubmitDiagnosticScanDto {
  @IsString()
  @IsOptional()
  scannedVin?: string;

  @IsString()
  @IsNotEmpty()
  transportType: string;

  @IsString()
  @IsNotEmpty()
  protocol: string;

  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  rawPayloads?: string[];

  @IsBoolean()
  @IsOptional()
  isClearCommand?: boolean;
}
