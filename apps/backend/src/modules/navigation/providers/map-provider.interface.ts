import { GeoPointDto } from '../dto/calculate-route.dto';

export interface RouteStep {
  instruction: string;
  distanceMeters: number;
  durationSeconds: number;
  type: string; // TURN_LEFT, TURN_RIGHT, STRAIGHT, ARRIVE, etc.
  maneuverPoint: GeoPointDto;
}

export interface RouteResult {
  routeId: string;
  distanceKm: number;
  durationMinutes: number;
  polyline: string; // Encoded polyline or coordinate array
  waypoints: GeoPointDto[];
  steps: RouteStep[];
  elevationGainMeters: number;
  twistinessScore: number; // 0.0 to 10.0 score for motorcycle routing
  provider: 'OSRM' | 'MAPBOX' | 'GOOGLE_MAPS';
}

export interface IMapRoutingProvider {
  name: string;
  calculateRoute(
    origin: GeoPointDto,
    destination: GeoPointDto,
    waypoints?: GeoPointDto[],
    preference?: 'SCENIC_TWISTY' | 'FASTEST' | 'AVOID_HIGHWAYS' | 'MOTORCYCLE_CUSTOM',
  ): Promise<RouteResult>;
}
