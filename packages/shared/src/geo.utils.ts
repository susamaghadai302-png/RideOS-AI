export class GeoUtils {
  private static readonly EARTH_RADIUS_KM = 6371;

  /**
   * Calculates Haversine distance in kilometers between two GPS points
   */
  public static calculateDistanceKm(
    lat1: number,
    lon1: number,
    lat2: number,
    lon2: number,
  ): number {
    const dLat = this.toRadians(lat2 - lat1);
    const dLon = this.toRadians(lon2 - lon1);

    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.toRadians(lat1)) *
        Math.cos(this.toRadians(lat2)) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);

    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return this.EARTH_RADIUS_KM * c;
  }

  /**
   * Estimates motorcycle lean angle based on speed (km/h) and turn radius (meters)
   */
  public static estimateLeanAngle(speedKmh: number, radiusMeters: number): number {
    if (radiusMeters <= 0) return 0;
    const speedMs = speedKmh / 3.6;
    const g = 9.81;
    const leanRad = Math.atan((speedMs * speedMs) / (radiusMeters * g));
    return Math.round((leanRad * 180) / Math.PI);
  }

  private static toRadians(degrees: number): number {
    return (degrees * Math.PI) / 180;
  }
}
