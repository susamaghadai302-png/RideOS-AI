export interface ObdSensorDataDto {
  riderId: string;
  rpm: number;
  engineTempC: number;
  throttlePct: number;
  batteryVoltage: number;
  frontTirePsi: number;
  rearTirePsi: number;
  frontTireTempC?: number;
  rearTireTempC?: number;
  diagnosticCodes: string[];
  timestamp: string;
}

export interface ObdDiagnosticReportDto {
  reportId: string;
  riderId: string;
  dtcList: { code: string; description: string; severity: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL' }[];
  tpmsWarning: boolean;
  tpmsMessage?: string;
  createdAt: string;
}
