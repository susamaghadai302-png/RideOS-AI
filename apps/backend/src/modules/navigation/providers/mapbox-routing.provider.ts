import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { IMapRoutingProvider, RouteResult, RouteStep } from './map-provider.interface';
import { GeoPointDto } from '../dto/calculate-route.dto';
import { OsrmRoutingProvider } from './osrm-routing.provider';
import { randomUUID } from 'crypto';

@Injectable()
export class MapboxRoutingProvider implements IMapRoutingProvider {
  readonly name = 'MAPBOX';
  private readonly logger = new Logger(MapboxRoutingProvider.name);

  constructor(
    private readonly configService: ConfigService,
    private readonly osrmProvider: OsrmRoutingProvider,
  ) {}

  async calculateRoute(
    origin: GeoPointDto,
    destination: GeoPointDto,
    waypoints: GeoPointDto[] = [],
    preference: string = 'SCENIC_TWISTY',
  ): Promise<RouteResult> {
    const token =
      this.configService.get<string>('MAPBOX_ACCESS_TOKEN') ||
      process.env.MAPBOX_ACCESS_TOKEN;

    if (!token || token.startsWith('YOUR_') || token === '') {
      this.logger.debug('[Mapbox] No access token configured. Delegating to OSRM provider.');
      return this.osrmProvider.calculateRoute(origin, destination, waypoints, preference);
    }

    try {
      const allPoints = [origin, ...waypoints, destination];
      const coordsString = allPoints.map((p) => `${p.lng},${p.lat}`).join(';');
      const profile = preference === 'AVOID_HIGHWAYS' ? 'driving' : 'driving-traffic';
      const url = `https://api.mapbox.com/directions/v5/mapbox/${profile}/${coordsString}?access_token=${token}&geometries=geojson&steps=true&overview=full`;

      this.logger.log(`[Mapbox] Requesting directions from ${origin.lat},${origin.lng} to ${destination.lat},${destination.lng}`);
      const response = await fetch(url, {
        method: 'GET',
        headers: { 'Accept': 'application/json' },
        signal: AbortSignal.timeout(10000),
      });

      if (response.ok) {
        const data = await response.json();
        if (data.code === 'Ok' && data.routes && data.routes.length > 0) {
          const mbRoute = data.routes[0];
          const distanceKm = parseFloat((mbRoute.distance / 1000).toFixed(2));
          const durationMinutes = Math.max(1, Math.round(mbRoute.duration / 60));

          const routeWaypoints: GeoPointDto[] = (mbRoute.geometry?.coordinates || []).map(
            (coord: [number, number]) => ({
              lat: parseFloat(coord[1].toFixed(6)),
              lng: parseFloat(coord[0].toFixed(6)),
            }),
          );

          const steps: RouteStep[] = [];
          if (Array.isArray(mbRoute.legs)) {
            for (const leg of mbRoute.legs) {
              if (Array.isArray(leg.steps)) {
                for (const step of leg.steps) {
                  const m = step.maneuver || {};
                  const type = this.mapMapboxManeuver(m.type, m.modifier);
                  const instruction = step.maneuver?.instruction || step.name || 'Continue';
                  const maneuverPoint: GeoPointDto = {
                    lat: m.location ? parseFloat(m.location[1].toFixed(6)) : origin.lat,
                    lng: m.location ? parseFloat(m.location[0].toFixed(6)) : origin.lng,
                  };

                  steps.push({
                    instruction,
                    distanceMeters: Math.round(step.distance || 0),
                    durationSeconds: Math.round(step.duration || 0),
                    type,
                    maneuverPoint,
                  });
                }
              }
            }
          }

          return {
            routeId: randomUUID(),
            distanceKm,
            durationMinutes,
            polyline: JSON.stringify(routeWaypoints.length > 0 ? routeWaypoints : allPoints),
            waypoints: routeWaypoints.length > 0 ? routeWaypoints : allPoints,
            steps: steps.length > 0 ? steps : [{
              instruction: 'Proceed to destination along Mapbox route',
              distanceMeters: Math.round(mbRoute.distance || 1000),
              durationSeconds: Math.round(mbRoute.duration || 60),
              type: 'DEPART',
              maneuverPoint: origin,
            }],
            elevationGainMeters: Math.round(distanceKm * 16),
            twistinessScore: preference === 'SCENIC_TWISTY' ? 8.5 : 4.8,
            provider: 'MAPBOX',
          };
        }
      }
    } catch (err: any) {
      this.logger.warn(`[Mapbox] Request failed: ${err.message}. Falling back to OSRM.`);
    }

    return this.osrmProvider.calculateRoute(origin, destination, waypoints, preference);
  }

  private mapMapboxManeuver(type?: string, modifier?: string): string {
    if (!type) return 'STRAIGHT';
    const t = type.toLowerCase();
    const m = (modifier || '').toLowerCase();
    if (t === 'depart') return 'DEPART';
    if (t === 'arrive') return 'ARRIVE';
    if (t === 'turn') {
      if (m.includes('left')) return 'TURN_LEFT';
      if (m.includes('right')) return 'TURN_RIGHT';
      if (m.includes('uturn')) return 'UTURN';
      return 'TURN_SLIGHT';
    }
    if (t === 'merge') return 'MERGE';
    if (t === 'off ramp' || t === 'fork') return 'EXIT';
    if (t === 'roundabout' || t === 'rotary') return 'ROUNDABOUT';
    return 'STRAIGHT';
  }
}
