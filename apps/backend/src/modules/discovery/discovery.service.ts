import { Injectable } from '@nestjs/common';
import { ScenicRouteCard } from '@rideos/travel';

@Injectable()
export class DiscoveryService {
  private readonly routes: ScenicRouteCard[] = [
    {
      id: 'route-1',
      title: 'Tail of the Dragon (Deals Gap)',
      locationName: 'North Carolina / Tennessee, USA',
      distanceKm: 18.0,
      estimatedDurationHours: 0.75,
      twistyRating: 5,
      difficulty: 'TECHNICAL',
      surfaceType: 'PAVED',
    },
    {
      id: 'route-2',
      title: 'Pacific Coast Highway (Big Sur)',
      locationName: 'California, USA',
      distanceKm: 145.0,
      estimatedDurationHours: 3.0,
      twistyRating: 4,
      difficulty: 'INTERMEDIATE',
      surfaceType: 'PAVED',
    },
    {
      id: 'route-3',
      title: 'Stelvio Pass Alpine Route',
      locationName: 'Eastern Alps, Italy',
      distanceKm: 47.0,
      estimatedDurationHours: 1.5,
      twistyRating: 5,
      difficulty: 'TECHNICAL',
      surfaceType: 'PAVED',
    },
  ];

  async getCuratedRoutes(difficulty?: string): Promise<ScenicRouteCard[]> {
    if (difficulty) {
      return this.routes.filter((r) => r.difficulty === difficulty.toUpperCase());
    }
    return this.routes;
  }
}
