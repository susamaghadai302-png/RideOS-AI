export type RouteDifficulty = 'NOVICE' | 'INTERMEDIATE' | 'TECHNICAL';
export type RoadSurfaceType = 'PAVED' | 'GRAVEL' | 'MIXED';

export interface ScenicRouteCard {
  id: string;
  title: string;
  locationName: string;
  distanceKm: number;
  estimatedDurationHours: number;
  twistyRating: number; // 1 to 5 stars
  difficulty: RouteDifficulty;
  surfaceType: RoadSurfaceType;
  coverImageUrl?: string;
}
