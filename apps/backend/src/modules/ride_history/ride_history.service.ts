import { Injectable } from '@nestjs/common';
import { RideHistorySummary } from '@rideos/telemetry';

@Injectable()
export class RideHistoryService {
  private readonly history: RideHistorySummary[] = [
    {
      tripId: 'trip-101',
      riderId: 'rider-001',
      startTime: new Date(Date.now() - 86400000).toISOString(),
      endTime: new Date(Date.now() - 82800000).toISOString(),
      totalDistanceKm: 142.5,
      durationMinutes: 60,
      avgSpeedKmh: 68.5,
      maxSpeedKmh: 124.0,
      maxLeanAngleLeft: 42.5,
      maxLeanAngleRight: 44.0,
      hardBrakingCount: 1,
      twistyScore: 92,
    },
  ];

  async getHistoryForRider(riderId: string): Promise<RideHistorySummary[]> {
    return this.history.filter((h) => h.riderId === riderId);
  }
}
