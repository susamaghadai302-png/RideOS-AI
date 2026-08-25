export interface RideHistorySummary {
  tripId: string;
  riderId: string;
  startTime: string;
  endTime: string;
  totalDistanceKm: number;
  durationMinutes: number;
  avgSpeedKmh: number;
  maxSpeedKmh: number;
  maxLeanAngleLeft: number;
  maxLeanAngleRight: number;
  hardBrakingCount: number;
  twistyScore: number;
}
