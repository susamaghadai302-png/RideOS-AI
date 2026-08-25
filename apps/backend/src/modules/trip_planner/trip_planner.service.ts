import { Injectable } from '@nestjs/common';
import { TripPlan, ScenicOptimizerService } from '@rideos/travel';

@Injectable()
export class TripPlannerService {
  async generateTouringPlan(
    title: string,
    originLat: number,
    originLng: number,
    destLat: number,
    destLng: number,
    maxDailyKm: number = 350,
  ): Promise<TripPlan> {
    const plan: TripPlan = {
      id: `trip-${Date.now()}`,
      title,
      totalDistanceKm: 720,
      totalDays: 2,
      days: [
        {
          dayNumber: 1,
          distanceKm: 360,
          estimatedRidingTimeHours: 5.5,
          stops: [
            { title: 'Origin Start', type: 'WAYPOINT', lat: originLat, lng: originLng },
            { title: 'Mountain Pass Fuel Stop', type: 'FUEL_STOP', lat: originLat + 0.5, lng: originLng + 0.5 },
            { title: 'Overnight Alpine Lodge', type: 'OVERNIGHT_HOTEL', lat: originLat + 1.2, lng: originLng + 1.2 },
          ],
        },
        {
          dayNumber: 2,
          distanceKm: 360,
          estimatedRidingTimeHours: 5.2,
          stops: [
            { title: 'Day 2 Departure', type: 'WAYPOINT', lat: originLat + 1.2, lng: originLng + 1.2 },
            { title: 'Coastline Scenic Overlook', type: 'SCENIC_REST', lat: destLat - 0.3, lng: destLng - 0.3 },
            { title: 'Final Destination', type: 'WAYPOINT', lat: destLat, lng: destLng },
          ],
        },
      ],
    };
    return plan;
  }

  exportPlanGpx(plan: TripPlan): string {
    return ScenicOptimizerService.exportToGpx(plan);
  }
}
