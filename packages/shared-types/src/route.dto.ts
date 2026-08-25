export interface GeoPointDto {
  lat: number;
  lng: number;
}

export interface RouteRequestDto {
  origin: GeoPointDto;
  destination: GeoPointDto;
  waypoints?: GeoPointDto[];
  preference: 'SCENIC_TWISTY' | 'FASTEST' | 'AVOID_HIGHWAYS';
}

export interface HazardReportDto {
  id?: string;
  type: 'GRAVEL' | 'OIL' | 'ACCIDENT' | 'CONSTRUCTION' | 'POLICE';
  severity: 'LOW' | 'MEDIUM' | 'HIGH';
  location: GeoPointDto;
  description?: string;
  createdAt?: string;
}
