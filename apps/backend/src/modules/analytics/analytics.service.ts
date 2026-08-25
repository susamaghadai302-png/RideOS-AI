import { Injectable } from '@nestjs/common';
import { RiderPerformanceScore, SafetyCalculatorService } from '@rideos/analytics';

export interface FleetAggregatedSummary {
  riderId: string;
  totalRides: number;
  totalDistanceKm: number;
  totalDurationMinutes: number;
  overallAverageSpeedKmh: number;
  topMaxSpeedKmh: number;
  overallMaxRpm: number;
  peakLeanAngleDeg: number;
  averagePacketLossPct: number;
  batteryHealthIndexPct: number;
  coolantThermalStabilityPct: number;
  activeDtcCount: number;
  fleetSafetyScore: number;
  recentRides: Array<{
    sessionId: string;
    date: string;
    distanceKm: number;
    durationMins: number;
    maxSpeedKmh: number;
    maxLeanAngleDeg: number;
  }>;
}

@Injectable()
export class AnalyticsService {
  async getRiderScore(riderId: string): Promise<RiderPerformanceScore> {
    const safety = SafetyCalculatorService.calculateSafetyScore(1, 142.5, 32);
    return {
      riderId,
      overallSafetyScore: safety,
      smoothnessScore: 94,
      corneringConsistencyScore: 88,
      totalKmRiddenLifetime: 4850.5,
      totalTripsCompleted: 38,
      riderRank: 'Apex Master',
    };
  }

  async getFleetSummary(riderId: string): Promise<FleetAggregatedSummary> {
    return {
      riderId,
      totalRides: 42,
      totalDistanceKm: 1248.5,
      totalDurationMinutes: 1860.0,
      overallAverageSpeedKmh: 48.6,
      topMaxSpeedKmh: 142.0,
      overallMaxRpm: 11200,
      peakLeanAngleDeg: 44.5,
      averagePacketLossPct: 0.12,
      batteryHealthIndexPct: 98.5,
      coolantThermalStabilityPct: 96.0,
      activeDtcCount: 0,
      fleetSafetyScore: 94,
      recentRides: [
        {
          sessionId: 'sess_17868001',
          date: new Date().toISOString(),
          distanceKm: 28.4,
          durationMins: 35.0,
          maxSpeedKmh: 118.0,
          maxLeanAngleDeg: 41.2,
        },
        {
          sessionId: 'sess_17868002',
          date: new Date(Date.now() - 86400000).toISOString(),
          distanceKm: 64.2,
          durationMins: 78.0,
          maxSpeedKmh: 135.5,
          maxLeanAngleDeg: 44.5,
        },
      ],
    };
  }
}
