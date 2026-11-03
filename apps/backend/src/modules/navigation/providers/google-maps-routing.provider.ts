import {
  Injectable,
  Logger,
  ServiceUnavailableException,
  HttpException,
  HttpStatus,
  BadRequestException,
  BadGatewayException,
  GatewayTimeoutException,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { IMapRoutingProvider, RouteResult, RouteStep } from './map-provider.interface';
import { GeoPointDto } from '../dto/calculate-route.dto';
import { OsrmRoutingProvider } from './osrm-routing.provider';
import { randomUUID } from 'crypto';

@Injectable()
export class GoogleMapsRoutingProvider implements IMapRoutingProvider {
  readonly name = 'GOOGLE_MAPS';
  private readonly logger = new Logger(GoogleMapsRoutingProvider.name);

  // Official Google Routes API endpoint
  private static readonly ROUTES_API_ENDPOINT =
    'https://routes.googleapis.com/directions/v2:computeRoutes';

  // Comprehensive field mask for motorcycle route metrics, polylines, instructions, maneuvers, and labels
  private static readonly ROUTES_API_FIELD_MASK =
    'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.description,routes.legs.steps,routes.routeLabels';

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
      this.configService.get<string>('GOOGLE_ROUTES_API_KEY') ||
      this.configService.get<string>('GOOGLE_MAPS_API_KEY') ||
      process.env.GOOGLE_ROUTES_API_KEY ||
      process.env.GOOGLE_MAPS_API_KEY;

    if (!apiKey || apiKey.startsWith('YOUR_') || apiKey.trim() === '') {
      if (process.env.NODE_ENV === 'production') {
        throw new ServiceUnavailableException(
          'Google Routes API key is not configured on the server. Motorcycle routing unavailable.',
        );
      }
      this.logger.debug('[Google Routes API] No server key configured. Falling back to development OSRM.');
      return this.osrmProvider.calculateRoute(origin, destination, waypoints, preference);
    }

    const requestBody: Record<string, any> = {
      origin: {
        location: {
          latLng: { latitude: origin.lat, longitude: origin.lng },
        },
      },
      destination: {
        location: {
          latLng: { latitude: destination.lat, longitude: destination.lng },
        },
      },
      travelMode: 'TWO_WHEELER',
      languageCode: 'en',
      computeAlternativeRoutes: true,
    };

    if (waypoints && waypoints.length > 0) {
      requestBody.intermediates = waypoints.map((w) => ({
        location: {
          latLng: { latitude: w.lat, longitude: w.lng },
        },
      }));
    }

    if (preference === 'AVOID_HIGHWAYS') {
      requestBody.routeModifiers = {
        avoidHighways: true,
        avoidTolls: true,
      };
    }

    this.logger.log(
      `[Google Routes API] Requesting TWO_WHEELER route: (${origin.lat}, ${origin.lng}) -> (${destination.lat}, ${destination.lng})`,
    );

    let response: Response;
    try {
      response = await fetch(GoogleMapsRoutingProvider.ROUTES_API_ENDPOINT, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Goog-Api-Key': apiKey,
          'X-Goog-FieldMask': GoogleMapsRoutingProvider.ROUTES_API_FIELD_MASK,
        },
        body: JSON.stringify(requestBody),
        signal: AbortSignal.timeout(10000),
      });
    } catch (err: any) {
      if (err.name === 'TimeoutError' || err.code === 23) {
        this.logger.error('[Google Routes API] Request timed out after 10000ms');
        throw new GatewayTimeoutException('Google Routes API request timed out.');
      }
      this.logger.error(`[Google Routes API] Network fetch error: ${err.message}`);
      throw new BadGatewayException(`Google Routes API communication error: ${err.message}`);
    }

    if (!response.ok) {
      const errorText = await response.text().catch(() => '');
      this.logger.error(`[Google Routes API] Upstream error: HTTP ${response.status} - ${errorText.slice(0, 200)}`);

      if (response.status === 401 || response.status === 403) {
        throw new ServiceUnavailableException('Google Routes API authorization failed. Check server key configuration.');
      }
      if (response.status === 429) {
        throw new HttpException('Google Routes API quota or rate limit exceeded.', HttpStatus.TOO_MANY_REQUESTS);
      }
      if (response.status === 400) {
        throw new BadRequestException('Google Routes API rejected route coordinates or parameters.');
      }
      throw new BadGatewayException(`Google Routes API failed with HTTP ${response.status}`);
    }

    let data: any;
    try {
      data = await response.json();
    } catch (e: any) {
      this.logger.error(`[Google Routes API] Failed to parse JSON response: ${e.message}`);
      throw new BadGatewayException('Malformed response from Google Routes API.');
    }

    if (!data.routes || !Array.isArray(data.routes) || data.routes.length === 0) {
      throw new NotFoundException('No motorcycle route found for the given origin and destination.');
    }

    const parsedRoutes: RouteResult[] = data.routes.map((r: any, index: number) =>
      this.parseGoogleRoute(r, origin, destination, preference, index),
    );

    const primaryRoute = parsedRoutes[0];
    if (parsedRoutes.length > 1) {
      primaryRoute.alternatives = parsedRoutes.slice(1);
    }

    return primaryRoute;
  }

  private parseGoogleRoute(
    route: any,
    origin: GeoPointDto,
    destination: GeoPointDto,
    preference: string,
    index: number,
  ): RouteResult {
    const distanceMeters = typeof route.distanceMeters === 'number' ? route.distanceMeters : 0;
    const durationStr = typeof route.duration === 'string' ? route.duration.replace('s', '') : '0';
    const durationSeconds = parseInt(durationStr, 10) || 0;

    const distanceKm = parseFloat((distanceMeters / 1000).toFixed(2));
    const durationMinutes = Math.max(1, Math.round(durationSeconds / 60));

    const overviewPolyline = route.polyline?.encodedPolyline || '';
    const decodedWaypoints = overviewPolyline
      ? this.decodePolyline(overviewPolyline)
      : [origin, destination];

    const steps: RouteStep[] = [];
    const legs = Array.isArray(route.legs) ? route.legs : [];

    for (const leg of legs) {
      const legSteps = Array.isArray(leg.steps) ? leg.steps : [];
      for (const step of legSteps) {
        const rawInstruction = step.navigationInstruction?.instructions?.trim() || '';
        const stepDist = typeof step.distanceMeters === 'number' ? step.distanceMeters : 0;
        const stepDurationStr = typeof step.staticDuration === 'string' ? step.staticDuration.replace('s', '') : '0';
        const stepDur = parseInt(stepDurationStr, 10) || 0;

        const maneuverPoint: GeoPointDto = step.startLocation?.latLng
          ? {
              lat: step.startLocation.latLng.latitude,
              lng: step.startLocation.latLng.longitude,
            }
          : origin;

        const stepPolyline = step.polyline?.encodedPolyline;
        const stepCoords = stepPolyline ? this.decodePolyline(stepPolyline) : undefined;

        steps.push({
          instruction: rawInstruction,
          distanceMeters: stepDist,
          durationSeconds: stepDur,
          type: this.mapGoogleManeuver(step.navigationInstruction?.maneuver),
          maneuverPoint,
          stepCoordinates: stepCoords,
        });
      }
    }

    const routeDescription = route.description || (index === 0 ? 'Fastest Highway' : `Alternative Route ${index}`);

    return {
      routeId: randomUUID(),
      distanceKm,
      durationMinutes,
      polyline: overviewPolyline,
      waypoints: decodedWaypoints,
      steps,
      elevationGainMeters: Math.round(distanceKm * 12),
      twistinessScore: preference === 'SCENIC_TWISTY' ? 7.5 : 4.0,
      provider: 'GOOGLE_MAPS',
      routeName: routeDescription,
    };
  }

  private mapGoogleManeuver(maneuver?: string): string {
    if (!maneuver) return 'STRAIGHT';
    const m = maneuver.toUpperCase();
    if (m === 'DEPART') return 'DEPART';
    if (m === 'ARRIVE' || m === 'DESTINATION') return 'ARRIVE';
    if (m.includes('LEFT')) return 'TURN_LEFT';
    if (m.includes('RIGHT')) return 'TURN_RIGHT';
    if (m.includes('UTURN') || m.includes('U_TURN')) return 'UTURN';
    if (m.includes('ROUNDABOUT')) return 'ROUNDABOUT';
    if (m.includes('MERGE')) return 'MERGE';
    if (m.includes('FORK')) return m.includes('LEFT') ? 'TURN_LEFT' : 'TURN_RIGHT';
    if (m.includes('RAMP')) return 'EXIT';
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
