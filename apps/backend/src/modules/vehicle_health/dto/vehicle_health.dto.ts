import { IsString, IsNotEmpty, IsOptional, IsNumber, IsBoolean, IsArray } from 'class-validator';

export class LogDiagnosticEventDto {
  @IsString()
  @IsNotEmpty()
  vehicleId: string;

  @IsString()
  @IsNotEmpty()
  code: string;

  @IsOptional()
  @IsString()
  source?: string;

  @IsOptional()
  @IsString()
  severity?: string;

  @IsString()
  @IsNotEmpty()
  description: string;

  @IsOptional()
  @IsString()
  tripId?: string;

  @IsOptional()
  rawData?: Record<string, any>;
}

export class CreateMaintenanceRecordDto {
  @IsString()
  @IsNotEmpty()
  vehicleId: string;

  @IsString()
  @IsNotEmpty()
  serviceType: string;

  @IsOptional()
  date?: Date;

  @IsNumber()
  odometerKm: number;

  @IsOptional()
  @IsBoolean()
  isVehicleOdometer?: boolean;

  @IsOptional()
  @IsString()
  notes?: string;

  @IsOptional()
  @IsNumber()
  cost?: number;

  @IsOptional()
  @IsString()
  serviceProvider?: string;

  @IsOptional()
  @IsArray()
  attachments?: string[];

  @IsOptional()
  nextDueDate?: Date;

  @IsOptional()
  @IsNumber()
  nextDueOdometerKm?: number;
}

export class CreateVehicleAlertDto {
  @IsString()
  @IsNotEmpty()
  vehicleId: string;

  @IsString()
  @IsNotEmpty()
  alertKey: string;

  @IsString()
  @IsNotEmpty()
  title: string;

  @IsString()
  @IsNotEmpty()
  message: string;

  @IsOptional()
  @IsString()
  category?: string;

  @IsOptional()
  @IsString()
  severity?: string;
}

export class CreateVehicleDocumentDto {
  @IsString()
  @IsNotEmpty()
  vehicleId: string;

  @IsString()
  @IsNotEmpty()
  docType: string;

  @IsString()
  @IsNotEmpty()
  title: string;

  @IsString()
  @IsNotEmpty()
  fileUrl: string;

  @IsOptional()
  @IsString()
  fileName?: string;

  @IsOptional()
  @IsString()
  mimeType?: string;

  @IsOptional()
  expiryDate?: Date;

  @IsOptional()
  @IsString()
  notes?: string;
}
