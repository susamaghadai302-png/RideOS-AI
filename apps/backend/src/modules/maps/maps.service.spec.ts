import { Test, TestingModule } from '@nestjs/testing';
import { MapsService } from './maps.service';

// Suppress logger output in tests
jest.spyOn(console, 'warn').mockImplementation(() => {});
jest.spyOn(console, 'log').mockImplementation(() => {});

describe('MapsService', () => {
  let service: MapsService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [MapsService],
    }).compile();

    service = module.get<MapsService>(MapsService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('searchPlaces', () => {
    it('should return top 5 curated suggestions when query is empty', async () => {
      const results = await service.searchPlaces('');
      expect(results.length).toBeLessThanOrEqual(5);
      expect(results.length).toBeGreaterThan(0);
    });

    it('should return matching results for "canyon" query', async () => {
      const results = await service.searchPlaces('canyon');
      expect(results.length).toBeGreaterThan(0);
      results.forEach((r) => {
        const matchesSearch =
          r.title.toLowerCase().includes('canyon') ||
          r.subtitle.toLowerCase().includes('canyon') ||
          r.category.toLowerCase().includes('canyon') ||
          (r.tags || []).some((t) => t.toLowerCase().includes('canyon'));
        expect(matchesSearch).toBe(true);
      });
    });

    it('should return matching results for "fuel" query', async () => {
      const results = await service.searchPlaces('fuel');
      expect(results.length).toBeGreaterThan(0);
    });

    it('should return empty array for unmatched query', async () => {
      const results = await service.searchPlaces('xxxxxxxxxxx_no_match_xxxx');
      expect(results).toEqual([]);
    });

    it('should perform case-insensitive search', async () => {
      const lowerResults = await service.searchPlaces('stelvio');
      const upperResults = await service.searchPlaces('STELVIO');
      expect(lowerResults.length).toBe(upperResults.length);
    });
  });

  describe('getNearbyPois', () => {
    it('should return curated POIs as fallback when Overpass API is unavailable', async () => {
      // Mock fetch to simulate network failure
      global.fetch = jest.fn().mockRejectedValue(new Error('Network error'));

      const pois = await service.getNearbyPois(37.7749, -122.4194, 10);
      expect(pois.length).toBeGreaterThan(0);
      pois.forEach((poi) => {
        expect(poi.id).toBeDefined();
        expect(poi.category).toBeDefined();
        expect(poi.title).toBeDefined();
        expect(poi.lat).toBeDefined();
        expect(poi.lng).toBeDefined();
      });
    });

    it('should return curated POIs when Overpass returns non-ok response', async () => {
      global.fetch = jest.fn().mockResolvedValue({
        ok: false,
        status: 429,
        json: async () => ({}),
      });

      const pois = await service.getNearbyPois(37.7749, -122.4194, 5);
      expect(pois.length).toBeGreaterThan(0);
    });

    it('should return curated POIs when Overpass returns empty elements', async () => {
      global.fetch = jest.fn().mockResolvedValue({
        ok: true,
        json: async () => ({ elements: [] }),
      });

      const pois = await service.getNearbyPois(37.7749, -122.4194, 5);
      expect(pois.length).toBeGreaterThan(0);
    });

    it('should map Overpass elements to PoiMarker format', async () => {
      const mockElements = [
        {
          id: 12345,
          lat: 37.775,
          lon: -122.42,
          tags: { amenity: 'fuel', name: 'Test Gas Station' },
        },
        {
          id: 67890,
          lat: 37.78,
          lon: -122.41,
          tags: { tourism: 'viewpoint', name: 'Scenic Overlook' },
        },
      ];

      global.fetch = jest.fn().mockResolvedValue({
        ok: true,
        json: async () => ({ elements: mockElements }),
      });

      const pois = await service.getNearbyPois(37.7749, -122.4194, 5);
      expect(pois.length).toBe(2);
      expect(pois[0].category).toBe('GAS_STATION');
      expect(pois[0].title).toBe('Test Gas Station');
      expect(pois[0].lat).toBe(37.775);
      expect(pois[1].category).toBe('SCENIC_LOOKOUT');
      expect(pois[1].title).toBe('Scenic Overlook');
    });

    it('should use fallback title when POI name is not set', async () => {
      const mockElements = [
        {
          id: 99999,
          lat: 37.775,
          lon: -122.42,
          tags: { amenity: 'fuel' },
        },
      ];

      global.fetch = jest.fn().mockResolvedValue({
        ok: true,
        json: async () => ({ elements: mockElements }),
      });

      const pois = await service.getNearbyPois(37.7749, -122.4194, 5);
      expect(pois[0].title).toBe('GAS_STATION POI');
    });
  });
});
