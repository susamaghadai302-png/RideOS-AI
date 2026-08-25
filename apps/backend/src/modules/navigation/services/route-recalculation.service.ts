import { Injectable } from '@nestjs/common';
import { GeoPointDto } from '../dto/calculate-route.dto';

@Injectable()
export class RouteRecalculationService {
  /**
   * Threshold distance in meters off-route before triggering automatic recalculation
   */
  private readonly OFF_ROUTE_THRESHOLD_METERS = 35.0;

  /**
   * Determines if the current rider position has deviated from the planned route polyline
   */
  isOffRoute(currentLocation: GeoPointDto, routeWaypoints: GeoPointDto[]): boolean {
    if (!routeWaypoints || routeWaypoints.length === 0) return false;

    let minDistance = Infinity;
    for (const point of routeWaypoints) {
      const dist = this.haversineMeters(currentLocation, point);
      if (dist < minDistance) {
        minDistance = dist;
      }
    }

    return minDistance > this.OFF_ROUTE_THRESHOLD_METERS;
  }

  private haversineMeters(p1: GeoPointDto, p2: GeoPointDto): number {
    const R = 6371000; // Earth radius in meters
    const dLat = (p2.lat - p1.lat) * (Math.PI / 180);
    const dLng = (p2.lng - p1.lng) * (Math.PI / 180);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(p1.lat * (Math.PI / 180)) *
        Math.cos(p2.lat * (Math.PI / 180)) *
        Math.sin(dLng / 2) *
        Math.sin(dLng / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }
}
