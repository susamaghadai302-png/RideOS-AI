import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { IMapRoutingProvider, RouteResult, RouteStep } from './map-provider.interface';
import { GeoPointDto } from '../dto/calculate-route.dto';
import { OsrmRoutingProvider } from './osrm-routing.provider';
import { randomUUID } from 'crypto';

@Injectable()
export class GoogleMapsRoutingProvider implements IMapRoutingProvider {
  readonly name = 'GOOGLE_MAPS';
  private readonly logger = new Logger(GoogleMapsRoutingProvider.name);

  constructor(
    private readonly configService: ConfigService,
    private readonly osrmProvider: OsrmRoutingProvider,
  ) {}

  async calculateRoute(
    origin: GeoPointDto,
    destination: GeoPointDto,
    waypoints: GeoPointDto[] = [],
    preference: string = 'FASTEST',
  ): Promise<RouteResult> {
    const apiKey =
      this.configService.get<string>('GOOGLE_MAPS_API_KEY') ||
      process.env.GOOGLE_MAPS_API_KEY;

    if (!apiKey || apiKey.startsWith('YOUR_') || apiKey === '') {
      this.logger.debug('[Google Maps] No API key configured. Delegating to OSRM provider.');
      return this.osrmProvider.calculateRoute(origin, destination, waypoints, preference);
    }

    try {
      let url = `https://maps.googleapis.com/maps/api/directions/json?origin=${origin.lat},${origin.lng}&destination=${destination.lat},${destination.lng}&mode=driving&key=${apiKey}`;

      if (waypoints.length > 0) {
        const wpString = waypoints.map((w) => `${w.lat},${w.lng}`).join('|');
        url += `&waypoints=${encodeURIComponent(wpString)}`;
      }

      if (preference === 'AVOID_HIGHWAYS') {
        url += '&avoid=highways|tolls';
      }

      this.logger.log(`[Google Maps] Requesting directions from ${origin.lat},${origin.lng} to ${destination.lat},${destination.lng}`);
      const response = await fetch(url, {
        method: 'GET',
        headers: { 'Accept': 'application/json' },
        signal: AbortSignal.timeout(10000),
      });

      if (response.ok) {
        const data = await response.json();
        if (data.status === 'OK' && data.routes && data.routes.length > 0) {
          const gRoute = data.routes[0];
          let totalDistanceMeters = 0;
          let totalDurationSeconds = 0;
          const steps: RouteStep[] = [];

          if (Array.isArray(gRoute.legs)) {
            for (const leg of gRoute.legs) {
              totalDistanceMeters += leg.distance?.value || 0;
              totalDurationSeconds += leg.duration?.value || 0;

              if (Array.isArray(leg.steps)) {
                for (const step of leg.steps) {
                  const rawInstruction = step.html_instructions || '';
                  const cleanInstruction = rawInstruction
                    .replace(/<[^>]*>?/gm, ' ')
                    .replace(/\s+/g, ' ')
                    .trim();

                  const maneuverPoint: GeoPointDto = {
                    lat: step.start_location?.lat ?? origin.lat,
                    lng: step.start_location?.lng ?? origin.lng,
                  };

                  steps.push({
                    instruction: cleanInstruction || 'Continue straight',
                    distanceMeters: step.distance?.value || 0,
                    durationSeconds: step.duration?.value || 0,
                    type: this.mapGoogleManeuver(step.maneuver),
                    maneuverPoint,
                  });
                }
              }
            }
          }

          // Decode overview polyline
          const decodedWaypoints = gRoute.overview_polyline?.points
            ? this.decodePolyline(gRoute.overview_polyline.points)
            : [origin, ...waypoints, destination];

          const distanceKm = parseFloat((totalDistanceMeters / 1000).toFixed(2));
          const durationMinutes = Math.max(1, Math.round(totalDurationSeconds / 60));

          return {
            routeId: randomUUID(),
            distanceKm,
            durationMinutes,
            polyline: JSON.stringify(decodedWaypoints),
            waypoints: decodedWaypoints,
            steps: steps.length > 0 ? steps : [{
              instruction: 'Proceed to destination along Google route',
              distanceMeters: totalDistanceMeters,
              durationSeconds: totalDurationSeconds,
              type: 'DEPART',
              maneuverPoint: origin,
            }],
            elevationGainMeters: Math.round(distanceKm * 15),
            twistinessScore: preference === 'SCENIC_TWISTY' ? 7.5 : 4.0,
            provider: 'GOOGLE_MAPS',
          };
        } else {
          this.logger.warn(`[Google Maps] Directions API returned status: ${data.status} (${data.error_message || 'No details'}). Falling back to OSRM.`);
        }
      }
    } catch (err: any) {
      this.logger.warn(`[Google Maps] Request failed: ${err.message}. Falling back to OSRM.`);
    }

    return this.osrmProvider.calculateRoute(origin, destination, waypoints, preference);
  }

  private mapGoogleManeuver(maneuver?: string): string {
    if (!maneuver) return 'STRAIGHT';
    const m = maneuver.toLowerCase();
    if (m.includes('turn-left') || m.includes('fork-left')) return 'TURN_LEFT';
    if (m.includes('turn-right') || m.includes('fork-right')) return 'TURN_RIGHT';
    if (m.includes('uturn')) return 'UTURN';
    if (m.includes('merge')) return 'MERGE';
    if (m.includes('ramp')) return 'EXIT';
    if (m.includes('roundabout')) return 'ROUNDABOUT';
    return 'STRAIGHT';
  }

  private decodePolyline(encoded: string): GeoPointDto[] {
    const points: GeoPointDto[] = [];
    let index = 0;
    const len = encoded.length;
    let lat = 0;
    let lng = 0;

    while (index < len) {
      let b: number;
      let shift = 0;
      let result = 0;
      do {
        b = encoded.charCodeAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      const dlat = result & 1 ? ~(result >> 1) : result >> 1;
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.charCodeAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      const dlng = result & 1 ? ~(result >> 1) : result >> 1;
      lng += dlng;

      points.push({
        lat: parseFloat((lat / 1e5).toFixed(6)),
        lng: parseFloat((lng / 1e5).toFixed(6)),
      });
    }

    return points;
  }
}
