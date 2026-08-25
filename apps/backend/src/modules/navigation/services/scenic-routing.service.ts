import { Injectable } from '@nestjs/common';
import { RouteResult } from '../providers/map-provider.interface';
import { GeoPointDto } from '../dto/calculate-route.dto';

@Injectable()
export class ScenicRoutingService {
  /**
   * Evaluates curve density, bearing changes, and elevation profile to compute a motorcycle twistiness score (1.0 to 10.0)
   */
  evaluateTwistinessScore(
    waypoints: GeoPointDto[],
    stepsCount: number,
    elevationGainMeters: number,
    distanceKm: number,
  ): number {
    if (distanceKm <= 0) return 5.0;

    let totalCurves = 0;
    let sharpHairpins = 0;
    let totalCurvatureAngle = 0;

    if (waypoints && waypoints.length >= 3) {
      for (let i = 1; i < waypoints.length - 1; i++) {
        const bearing1 = this.calculateBearing(waypoints[i - 1], waypoints[i]);
        const bearing2 = this.calculateBearing(waypoints[i], waypoints[i + 1]);
        let angleDelta = Math.abs(bearing2 - bearing1);
        if (angleDelta > 180) {
          angleDelta = 360 - angleDelta;
        }

        if (angleDelta >= 15) {
          totalCurves++;
          totalCurvatureAngle += angleDelta;
          if (angleDelta >= 45) {
            sharpHairpins++;
          }
        }
      }
    }

    if (totalCurves > 0) {
      const curveDensityPerKm = totalCurves / distanceKm;
      const hairpinBonus = (sharpHairpins / distanceKm) * 1.5;
      const avgCurveAngle = totalCurvatureAngle / totalCurves;
      const angleFactor = (avgCurveAngle / 60) * 2.0;

      const geometricScore = 1.5 + curveDensityPerKm * 1.4 + hairpinBonus + angleFactor;
      return parseFloat(Math.min(Math.max(geometricScore, 1.0), 10.0).toFixed(1));
    }

    // Heuristic fallback based on step count and elevation
    const curveDensity = stepsCount / distanceKm;
    const elevationDensity = elevationGainMeters / distanceKm;
    const rawScore = curveDensity * 2.5 + elevationDensity * 0.05 + 1.0;
    return parseFloat(Math.min(Math.max(rawScore, 1.0), 10.0).toFixed(1));
  }

  /**
   * Applies motorcycle scenic weighting to a base route
   */
  applyMotorcycleOptimization(baseRoute: RouteResult): RouteResult {
    const twistiness = this.evaluateTwistinessScore(
      baseRoute.waypoints,
      baseRoute.steps.length,
      baseRoute.elevationGainMeters,
      baseRoute.distanceKm,
    );

    return {
      ...baseRoute,
      twistinessScore: twistiness,
    };
  }

  private calculateBearing(p1: GeoPointDto, p2: GeoPointDto): number {
    const lat1 = (p1.lat * Math.PI) / 180;
    const lat2 = (p2.lat * Math.PI) / 180;
    const dLng = ((p2.lng - p1.lng) * Math.PI) / 180;

    const y = Math.sin(dLng) * Math.cos(lat2);
    const x =
      Math.cos(lat1) * Math.sin(lat2) -
      Math.sin(lat1) * Math.cos(lat2) * Math.cos(dLng);
    const brng = (Math.atan2(y, x) * 180) / Math.PI;
    return (brng + 360) % 360;
  }
}
