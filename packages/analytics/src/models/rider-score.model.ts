export interface RiderPerformanceScore {
  riderId: string;
  overallSafetyScore: number; // 0 - 100
  smoothnessScore: number | null; // 0 - 100
  corneringConsistencyScore: number | null; // 0 - 100
  totalKmRiddenLifetime: number;
  totalTripsCompleted: number;
  riderRank: string; // e.g. "Apex Master", "Curvy Cruiser", "Pro Rider"
}
