export interface TelemetrySensorSample {
  tripId: string;
  timestamp: string; // ISO String
  lat: number;
  lng: number;
  speedKmh: number;
  leanAngleDegrees: number;
  accelG: number;
  gyroX: number;
  gyroY: number;
  gyroZ: number;
  elevationMeters: number;
}
