import { IsNumber, IsArray, IsOptional, IsString } from 'class-validator';

export class StreamObdDataDto {
  @IsNumber()
  rpm: number;

  @IsNumber()
  engineTempC: number;

  @IsNumber()
  throttlePct: number;

  @IsNumber()
  batteryVoltage: number;

  @IsNumber()
  frontTirePsi: number;

  @IsNumber()
  rearTirePsi: number;

  @IsNumber()
  @IsOptional()
  frontTireTempC?: number;

  @IsNumber()
  @IsOptional()
  rearTireTempC?: number;

  @IsArray()
  @IsString({ each: true })
  diagnosticCodes: string[];
}
