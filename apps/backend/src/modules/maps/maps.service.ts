import { Injectable, Logger } from '@nestjs/common';
import { PoiMarker } from '@rideos/maps';

export interface PlaceSearchResult {
  id: string;
  title: string;
  subtitle: string;
  category: string;
  lat: number;
  lng: number;
  distanceKm: number;
  rating?: number;
  tags?: string[];
}

@Injectable()
export class MapsService {
  private readonly logger = new Logger(MapsService.name);

  /**
   * Fetch nearby POIs using OpenStreetMap Overpass API (free, no key required).
   * Throws if the API call fails or times out.
   */
  async getNearbyPois(lat: number, lng: number, radiusKm: number = 10): Promise<PoiMarker[]> {
    const radiusMeters = radiusKm * 1000;

    try {
      const overpassQuery = `
        [out:json][timeout:8];
        (
          node["amenity"="fuel"](around:${radiusMeters},${lat},${lng});
          node["tourism"="viewpoint"](around:${radiusMeters},${lat},${lng});
          node["shop"="motorcycle"](around:${radiusMeters},${lat},${lng});
          node["amenity"="cafe"](around:${radiusMeters},${lat},${lng});
        );
        out body 20;
      `;

      const response = await fetch('https://overpass-api.de/api/interpreter', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: `data=${encodeURIComponent(overpassQuery)}`,
        signal: AbortSignal.timeout(8000),
      });

      if (!response.ok) {
        throw new Error(`Overpass API returned ${response.status}`);
      }

      const data = await response.json();
      const elements = data.elements || [];

      if (elements.length === 0) {
        return [];
      }

      return elements.map((el: any, idx: number) => {
        const tags = el.tags || {};
        const amenity = tags.amenity || tags.tourism || tags.shop || 'UNKNOWN';
        const category = this.mapOsmCategory(amenity);

        return {
          id: `osm-${el.id || idx}`,
          category,
          title: tags.name || `${category} POI`,
          lat: el.lat,
          lng: el.lon,
          rating: undefined,
        } as PoiMarker;
      });
    } catch (error: any) {
      this.logger.error(`Overpass API error: ${error.message}`);
      throw new Error('POI provider unavailable');
    }
  }

  private mapOsmCategory(amenity: string): string {
    const mapping: Record<string, string> = {
      fuel: 'GAS_STATION',
      viewpoint: 'SCENIC_LOOKOUT',
      motorcycle: 'SERVICE_WORKSHOP',
      cafe: 'MEETUP_POINT',
    };
    return mapping[amenity] || 'GENERAL';
  }

  /**
   * Search places using Nominatim.
   */
  async searchPlaces(query: string): Promise<PlaceSearchResult[]> {
    if (!query || query.trim().length === 0) {
      return [];
    }
    
    try {
      const response = await fetch(`https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(query)}&format=json&limit=5`);
      if (!response.ok) {
        throw new Error('Nominatim returned error');
      }
      
      const data = await response.json();
      return data.map((d: any) => ({
        id: `nom-${d.place_id}`,
        title: d.name || d.display_name.split(',')[0],
        subtitle: d.display_name,
        category: d.type?.toUpperCase() || 'GENERAL',
        lat: parseFloat(d.lat),
        lng: parseFloat(d.lon),
        distanceKm: 0,
      }));
    } catch (e: any) {
      this.logger.error(`Search provider error: ${e.message}`);
      throw new Error('Search provider unavailable');
    }
  }
}
