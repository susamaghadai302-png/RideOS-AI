import { Injectable } from '@nestjs/common';
import { RiderPerformanceScore, SafetyCalculatorService } from '@rideos/analytics';
import { TripsService } from '../trips/trips.service';

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
  constructor(private readonly tripsService: TripsService) {}

  async getRiderScore(riderId: string): Promise<RiderPerformanceScore> {
    const { trips } = await this.tripsService.getUserTrips(riderId, 1000, 0);

    let totalKm = 0;
    let topMaxSpeed = 0;

    for (const t of trips) {
      totalKm += t.distanceKm || 0;
      if (t.maxSpeedKmh && t.maxSpeedKmh > topMaxSpeed) {
        topMaxSpeed = t.maxSpeedKmh;
      }
    }

    const safety = trips.length > 0 ? SafetyCalculatorService.calculateSafetyScore(trips.length, topMaxSpeed, 0) : 0;

    return {
      riderId,
      overallSafetyScore: trips.length > 0 ? safety : 0,
      smoothnessScore: trips.length > 0 ? 80 : 0, // Mock fallback for unused metrics
      corneringConsistencyScore: trips.length > 0 ? 80 : 0,
      totalKmRiddenLifetime: totalKm,
      totalTripsCompleted: trips.length,
      riderRank: trips.length > 0 ? 'Active Rider' : 'Rookie',
    };
  }

  async getFleetSummary(riderId: string): Promise<FleetAggregatedSummary> {
    const { trips } = await this.tripsService.getUserTrips(riderId, 10, 0);

    let totalKm = 0;
    let totalDur = 0;
    let topSpeed = 0;
    let sumAvgSpeed = 0;
    let validAvgSpeedCount = 0;

    const recentRides = trips.slice(0, 5).map(t => ({
      sessionId: t.tripId,
      date: t.startTime.toISOString(),
      distanceKm: t.distanceKm || 0,
      durationMins: (t.durationSeconds || 0) / 60,
      maxSpeedKmh: t.maxSpeedKmh || 0,
      maxLeanAngleDeg: 0, // Missing in trip schema
    }));

    for (const t of trips) {
      totalKm += t.distanceKm || 0;
      totalDur += t.durationSeconds || 0;
      if (t.maxSpeedKmh && t.maxSpeedKmh > topSpeed) topSpeed = t.maxSpeedKmh;
      if (t.avgSpeedKmh) {
        sumAvgSpeed += t.avgSpeedKmh;
        validAvgSpeedCount++;
      }
    }

    const avgSpeed = validAvgSpeedCount > 0 ? (sumAvgSpeed / validAvgSpeedCount) : 0;
    const safety = trips.length > 0 ? SafetyCalculatorService.calculateSafetyScore(trips.length, topSpeed, 0) : 0;

    return {
      riderId,
      totalRides: trips.length,
      totalDistanceKm: totalKm,
      totalDurationMinutes: totalDur / 60,
      overallAverageSpeedKmh: avgSpeed,
      topMaxSpeedKmh: topSpeed,
      overallMaxRpm: trips.length > 0 ? 8000 : 0, // Placeholder
      peakLeanAngleDeg: 0,
      averagePacketLossPct: 0,
      batteryHealthIndexPct: trips.length > 0 ? 100 : 0,
      coolantThermalStabilityPct: trips.length > 0 ? 100 : 0,
      activeDtcCount: 0,
      fleetSafetyScore: safety,
      recentRides,
    };
  }
}
