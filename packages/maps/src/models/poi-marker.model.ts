export type PoiCategory =
  | 'GAS_STATION'
  | 'SCENIC_LOOKOUT'
  | 'MOTORCYCLE_REPAIR'
  | 'ROAD_HAZARD'
  | 'SPEED_CAMERA'
  | 'REST_STOP';

export interface PoiMarker {
  id: string;
  category: PoiCategory;
  title: string;
  description?: string;
  lat: number;
  lng: number;
  rating?: number;
}
