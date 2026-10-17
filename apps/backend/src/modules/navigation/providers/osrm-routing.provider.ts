import { Injectable, Logger } from '@nestjs/common';
import { IMapRoutingProvider, RouteResult, RouteStep } from './map-provider.interface';
import { GeoPointDto } from '../dto/calculate-route.dto';
import { randomUUID } from 'crypto';

@Injectable()
export class OsrmRoutingProvider implements IMapRoutingProvider {
  readonly name = 'OSRM';
  private readonly logger = new Logger(OsrmRoutingProvider.name);

  async calculateRoute(
    origin: GeoPointDto,
    destination: GeoPointDto,
    waypoints: GeoPointDto[] = [],
    preference: string = 'SCENIC_TWISTY',
  ): Promise<RouteResult> {
    const allPoints = [origin, ...waypoints, destination];
    const coordsString = allPoints.map((p) => `${p.lng},${p.lat}`).join(';');
    const rawBaseUrl = process.env.OSRM_BASE_URL || process.env.ROUTING_API_BASE_URL;
    let baseUrl = rawBaseUrl;
    if (!baseUrl) {
      if (process.env.NODE_ENV === 'production') {
        throw new Error(
          'OSRM routing provider is unconfigured in production. Explicit OSRM_BASE_URL or ROUTING_API_BASE_URL is required to protect rider safety.',
        );
      }
      baseUrl = 'https://router.project-osrm.org/route/v1/driving';
    }
    const cleanBaseUrl = baseUrl.endsWith('/') ? baseUrl.slice(0, -1) : baseUrl;
    const url = `${cleanBaseUrl}/${coordsString}?overview=full&geometries=geojson&steps=true`;

    try {
      this.logger.log(`[OSRM] Requesting live route from ${origin.lat},${origin.lng} to ${destination.lat},${destination.lng}`);
      const response = await fetch(url, {
        method: 'GET',
        headers: { 'Accept': 'application/json' },
        signal: AbortSignal.timeout(10000),
      });

      if (response.ok) {
        const data = await response.json();
        if (data.code === 'Ok' && data.routes && data.routes.length > 0) {
          const osrmRoute = data.routes[0];
          const distanceKm = parseFloat((osrmRoute.distance / 1000).toFixed(2));
          const durationMinutes = Math.max(1, Math.round(osrmRoute.duration / 60));

          // Parse GeoJSON coordinates -> waypoints
          const routeWaypoints: GeoPointDto[] = (osrmRoute.geometry?.coordinates || []).map(
            (coord: [number, number]) => ({
              lat: parseFloat(coord[1].toFixed(6)),
              lng: parseFloat(coord[0].toFixed(6)),
            }),
          );

          // Parse Turn-by-Turn Steps from all legs
          const steps: RouteStep[] = [];
          if (Array.isArray(osrmRoute.legs)) {
            for (const leg of osrmRoute.legs) {
              if (Array.isArray(leg.steps)) {
                for (const step of leg.steps) {
                  const m = step.maneuver || {};
                  const type = this.mapManeuverType(m.type, m.modifier);
                  const instruction = this.buildInstruction(step.name, m.type, m.modifier);
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

          if (steps.length === 0) {
            steps.push({
              instruction: 'Proceed to destination along planned route',
              distanceMeters: Math.round(osrmRoute.distance || 1000),
              durationSeconds: Math.round(osrmRoute.duration || 60),
              type: 'DEPART',
              maneuverPoint: origin,
            });
          }

          return {
            routeId: randomUUID(),
            distanceKm,
            durationMinutes,
            polyline: JSON.stringify(routeWaypoints.length > 0 ? routeWaypoints : allPoints),
            waypoints: routeWaypoints.length > 0 ? routeWaypoints : allPoints,
            steps,
            elevationGainMeters: Math.round(distanceKm * 18),
            twistinessScore: preference === 'SCENIC_TWISTY' ? 8.2 : 5.0,
            provider: 'OSRM',
          };
        }
      }
    } catch (err: any) {
      this.logger.error(`[OSRM] Live routing request failed (${err.message}).`);
    }

    throw new Error('OSRM routing provider failed to calculate a route.');
  }

  private mapManeuverType(type?: string, modifier?: string): string {
    if (!type) return 'STRAIGHT';
    const lowerType = type.toLowerCase();
    const lowerMod = (modifier || '').toLowerCase();

    if (lowerType === 'depart') return 'DEPART';
    if (lowerType === 'arrive') return 'ARRIVE';
    if (lowerType === 'turn' || lowerType === 'end of road') {
      if (lowerMod.includes('left')) return 'TURN_LEFT';
      if (lowerMod.includes('right')) return 'TURN_RIGHT';
      if (lowerMod.includes('uturn')) return 'UTURN';
      return 'TURN_SLIGHT';
    }
    if (lowerType === 'merge' || lowerType === 'on ramp') return 'MERGE';
    if (lowerType === 'off ramp' || lowerType === 'fork') return 'EXIT';
    if (lowerType === 'roundabout' || lowerType === 'rotary') return 'ROUNDABOUT';
    return 'STRAIGHT';
  }

  private buildInstruction(streetName?: string, type?: string, modifier?: string): string {
    const road = streetName && streetName.trim().length > 0 ? streetName.trim() : 'road';
    const lowerType = (type || '').toLowerCase();
    const lowerMod = (modifier || '').toLowerCase();

    if (lowerType === 'depart') return `Head out on ${road}`;
    if (lowerType === 'arrive') return `Arrive at destination on ${road}`;
    if (lowerType === 'roundabout' || lowerType === 'rotary') return `Enter roundabout and take exit onto ${road}`;
    if (lowerType === 'fork') return `Keep ${lowerMod.includes('left') ? 'left' : 'right'} at the fork onto ${road}`;
    if (lowerType === 'merge') return `Merge onto ${road}`;
    if (lowerType === 'off ramp') return `Take exit onto ${road}`;
    if (lowerType === 'on ramp') return `Take ramp onto ${road}`;

    if (lowerMod.includes('sharp left')) return `Sharp left onto ${road}`;
    if (lowerMod.includes('sharp right')) return `Sharp right onto ${road}`;
    if (lowerMod.includes('slight left')) return `Slight left onto ${road}`;
    if (lowerMod.includes('slight right')) return `Slight right onto ${road}`;
    if (lowerMod.includes('left')) return `Turn left onto ${road}`;
    if (lowerMod.includes('right')) return `Turn right onto ${road}`;
    if (lowerMod.includes('uturn')) return `Make a U-turn onto ${road}`;

    return `Continue onto ${road}`;
  }

  private estimateDistanceKm(p1: GeoPointDto, p2: GeoPointDto): number {
    const R = 6371; // Earth radius in km
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
