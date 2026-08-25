export interface TelemetryPayloadDto {
  tripId: string;
  timestamp: string;
  lat: number;
  lng: number;
  speedKmh: number;
  leanAngle: number;
  accelG: number;
  elevationM: number;
  batteryLevel: number;
}

export interface TripSummaryDto {
  tripId: string;
  riderId: string;
  startTime: string;
  endTime: string;
  totalDistanceKm: number;
  avgSpeedKmh: number;
  maxSpeedKmh: number;
  maxLeanAngleLeft: number;
  maxLeanAngleRight: number;
  hardBrakingEvents: number;
}
