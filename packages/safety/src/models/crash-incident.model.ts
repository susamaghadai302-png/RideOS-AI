export type CrashSeverity = 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';

export interface CrashIncident {
  id: string;
  riderId: string;
  timestamp: string;
  lat: number;
  lng: number;
  peakGForce: number;
  tiltAngleDegrees: number;
  speedPriorKmh: number;
  severity: CrashSeverity;
}
