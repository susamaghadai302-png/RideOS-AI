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

  // Curated motorcycle-focused POI fallback data
  private readonly curatedPois: PoiMarker[] = [
    {
      id: 'poi-1',
      category: 'GAS_STATION',
      title: 'Shell High Octane Station',
      lat: 37.7749,
      lng: -122.4194,
      rating: 4.8,
    },
    {
      id: 'poi-2',
      category: 'SCENIC_LOOKOUT',
      title: 'Skyline Ridge Overlook',
      lat: 37.7833,
      lng: -122.4167,
      rating: 4.9,
    },
    {
      id: 'poi-3',
      category: 'ROAD_HAZARD',
      title: 'Gravel Trap on Hairpin Turn',
      lat: 37.765,
      lng: -122.42,
    },
  ];

  // Directory of curated motorcycle routes, waypoints, and destinations
  private readonly placeDirectory: PlaceSearchResult[] = [
    {
      id: 'dest-canyon-pass',
      title: 'Angeles Crest Canyon Pass',
      subtitle: 'Mountain Highway 2 • High Elevation Sweep',
      category: 'CANYON_ROUTE',
      lat: 34.2811,
      lng: -118.0648,
      distanceKm: 14.8,
      rating: 4.9,
      tags: ['canyon', 'twisties', 'apex', 'curves', 'scenic'],
    },
    {
      id: 'dest-skyline-blvd',
      title: 'Skyline Boulevard Summit',
      subtitle: 'CA-35 Ridge Route • Redwood Forest',
      category: 'SCENIC_ROUTE',
      lat: 37.3195,
      lng: -122.1852,
      distanceKm: 22.4,
      rating: 4.95,
      tags: ['skyline', 'ridge', 'redwood', 'scenic', 'views'],
    },
    {
      id: 'dest-pacific-coast',
      title: 'Pacific Coast Highway 1',
      subtitle: 'Big Sur Coastal Sweep • Oceanfront',
      category: 'COASTAL_HIGHWAY',
      lat: 36.3168,
      lng: -121.8885,
      distanceKm: 48.0,
      rating: 5.0,
      tags: ['coastal', 'pch', 'highway 1', 'ocean', 'touring'],
    },
    {
      id: 'dest-apex-service',
      title: 'Apex Performance Moto Lab',
      subtitle: 'Dyno Tuning & Brembo Brake Service',
      category: 'SERVICE_WORKSHOP',
      lat: 37.7812,
      lng: -122.4125,
      distanceKm: 3.2,
      rating: 4.85,
      tags: ['service', 'workshop', 'mechanic', 'tires', 'brakes', 'dyno'],
    },
    {
      id: 'dest-shell-100',
      title: 'Shell 100-Octane V-Power Station',
      subtitle: 'Trackside High-Octane Fuel & Tire Pressure',
      category: 'FUEL_STATION',
      lat: 37.7749,
      lng: -122.4194,
      distanceKm: 1.5,
      rating: 4.8,
      tags: ['fuel', 'gas', 'octane', 'air', 'station'],
    },
    {
      id: 'dest-rock-store',
      title: 'The Rock Store Rider Meetup',
      subtitle: 'Mulholland Highway • Weekend Rider Hub',
      category: 'MEETUP_POINT',
      lat: 34.0988,
      lng: -118.7845,
      distanceKm: 18.5,
      rating: 4.9,
      tags: ['meetup', 'cafe', 'riders', 'squad', 'mulholland'],
    },
    {
      id: 'dest-tail-dragon',
      title: 'Tail of the Dragon Overlook',
      subtitle: 'US-129 • 318 Curves in 11 Miles',
      category: 'CANYON_ROUTE',
      lat: 35.5175,
      lng: -83.9288,
      distanceKm: 65.0,
      rating: 5.0,
      tags: ['dragon', 'curves', 'hairpin', 'extreme', 'twisties'],
    },
    {
      id: 'dest-alpine-pass',
      title: 'Stelvio Alpine Pass Lookout',
      subtitle: 'High Altitude Hairpins & Panoramic Views',
      category: 'ALPINE_PASS',
      lat: 46.5294,
      lng: 10.4531,
      distanceKm: 85.0,
      rating: 4.98,
      tags: ['alpine', 'pass', 'mountains', 'altitude', 'stelvio'],
    },
    {
      id: 'dest-chevron-racing',
      title: 'Chevron Supreme Racing Fuel',
      subtitle: '94-Octane & Touchless Visor Wash Station',
      category: 'FUEL_STATION',
      lat: 37.7915,
      lng: -122.4042,
      distanceKm: 4.1,
      rating: 4.7,
      tags: ['fuel', 'gas', 'chevron', 'station'],
    },
    {
      id: 'dest-motohub-cafe',
      title: 'Ace Cafe Rider Sanctuary',
      subtitle: 'Specialty Espresso & Rider Gear Lounge',
      category: 'MEETUP_POINT',
      lat: 37.7698,
      lng: -122.4468,
      distanceKm: 2.8,
      rating: 4.9,
      tags: ['cafe', 'coffee', 'meetup', 'lounge', 'squad'],
    },
  ];

  /**
   * Fetch nearby POIs using OpenStreetMap Overpass API (free, no key required).
   * Falls back to curated data if the API call fails or times out.
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
        this.logger.warn(`Overpass API returned ${response.status}, using curated POIs`);
        return this.curatedPois;
      }

      const data = await response.json();
      const elements = data.elements || [];

      if (elements.length === 0) {
        return this.curatedPois;
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
      this.logger.warn(`Overpass API error: ${error.message}. Returning curated POIs.`);
      return this.curatedPois;
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
   * Performs high-speed local directory search for routes, waypoints, and points of interest.
   * Can be swapped for live geocoding provider (Mapbox / Google Places) via .env without breaking client contracts.
   */
  async searchPlaces(query: string): Promise<PlaceSearchResult[]> {
    if (!query || query.trim().length === 0) {
      return this.placeDirectory.slice(0, 5); // Return top curated suggestions
    }

    const q = query.trim().toLowerCase();
    return this.placeDirectory.filter((place) => {
      const matchTitle = place.title.toLowerCase().includes(q);
      const matchSubtitle = place.subtitle.toLowerCase().includes(q);
      const matchCategory = place.category.toLowerCase().includes(q);
      const matchTags = place.tags?.some((t) => t.toLowerCase().includes(q)) ?? false;
      return matchTitle || matchSubtitle || matchCategory || matchTags;
    });
  }
}
