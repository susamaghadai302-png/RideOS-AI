import { GeoUtils } from '@rideos/shared';

export class RerouteDetectorService {
  private static readonly REROUTE_THRESHOLD_METERS = 30;

  /**
   * Determines if current rider position has drifted off the planned polyline route
   */
  public static isOffRoute(
    riderLat: number,
    riderLng: number,
    routeGeometry: Array<[number, number]>,
  ): boolean {
    if (routeGeometry.length === 0) return false;

    let minDistanceKm = Number.MAX_VALUE;

    for (const [lat, lng] of routeGeometry) {
      const dist = GeoUtils.calculateDistanceKm(riderLat, riderLng, lat, lng);
      if (dist < minDistanceKm) {
        minDistanceKm = dist;
      }
    }

    const minDistanceMeters = minDistanceKm * 1000;
    return minDistanceMeters > this.REROUTE_THRESHOLD_METERS;
  }
}
