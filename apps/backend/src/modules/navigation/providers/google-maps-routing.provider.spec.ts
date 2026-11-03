import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import {
  ServiceUnavailableException,
  HttpException,
  HttpStatus,
  BadRequestException,
  BadGatewayException,
  GatewayTimeoutException,
  NotFoundException,
} from '@nestjs/common';
import { GoogleMapsRoutingProvider } from './google-maps-routing.provider';
import { OsrmRoutingProvider } from './osrm-routing.provider';

describe('GoogleMapsRoutingProvider', () => {
  let provider: GoogleMapsRoutingProvider;
  let configService: ConfigService;
  let osrmProvider: OsrmRoutingProvider;

  const mockConfigService = {
    get: jest.fn(),
  };

  const mockOsrmProvider = {
    calculateRoute: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GoogleMapsRoutingProvider,
        { provide: ConfigService, useValue: mockConfigService },
        { provide: OsrmRoutingProvider, useValue: mockOsrmProvider },
      ],
    }).compile();

    provider = module.get<GoogleMapsRoutingProvider>(GoogleMapsRoutingProvider);
    configService = module.get<ConfigService>(ConfigService);
    osrmProvider = module.get<OsrmRoutingProvider>(OsrmRoutingProvider);
  });

  it('should be defined', () => {
    expect(provider).toBeDefined();
    expect(provider.name).toBe('GOOGLE_MAPS');
  });

  describe('calculateRoute with Google Routes API TWO_WHEELER', () => {
    const origin = { lat: 20.2961, lng: 85.8245 };
    const destination = { lat: 20.3533, lng: 85.8178 };

    it('should throw ServiceUnavailableException in production if API key is missing', async () => {
      const origEnv = process.env.NODE_ENV;
      process.env.NODE_ENV = 'production';
      mockConfigService.get.mockReturnValue(undefined);

      await expect(provider.calculateRoute(origin, destination)).rejects.toThrow(
        ServiceUnavailableException,
      );

      process.env.NODE_ENV = origEnv;
    });

    it('should delegate to OSRM in development if no key configured', async () => {
      const origEnv = process.env.NODE_ENV;
      process.env.NODE_ENV = 'development';
      mockConfigService.get.mockReturnValue(undefined);
      mockOsrmProvider.calculateRoute.mockResolvedValue({
        routeId: 'osrm-1',
        distanceKm: 5.0,
        durationMinutes: 10,
        polyline: 'abc',
        waypoints: [origin, destination],
        steps: [],
        elevationGainMeters: 50,
        twistinessScore: 4.0,
        provider: 'OSRM',
      });

      const result = await provider.calculateRoute(origin, destination);
      expect(osrmProvider.calculateRoute).toHaveBeenCalled();
      expect(result.provider).toBe('OSRM');

      process.env.NODE_ENV = origEnv;
    });

    it('should execute computeRoutes with travelMode TWO_WHEELER and parse real motorcycle route data', async () => {
      mockConfigService.get.mockReturnValue('test-api-key-12345');

      const mockRoutesApiResponse = {
        routes: [
          {
            description: 'Nandankanan Rd',
            distanceMeters: 7473,
            duration: '1087s',
            polyline: {
              encodedPolyline: 'whanDo`t~M',
            },
            legs: [
              {
                steps: [
                  {
                    distanceMeters: 500,
                    staticDuration: '60s',
                    navigationInstruction: {
                      maneuver: 'DEPART',
                      instructions: 'Head north on Nandankanan Rd',
                    },
                    startLocation: {
                      latLng: { latitude: 20.2961, longitude: 85.8245 },
                    },
                  },
                  {
                    distanceMeters: 6973,
                    staticDuration: '1027s',
                    navigationInstruction: {
                      maneuver: 'TURN_LEFT',
                      instructions: 'Turn left onto KIIT Rd',
                    },
                    startLocation: {
                      latLng: { latitude: 20.3000, longitude: 85.8200 },
                    },
                  },
                ],
              },
            ],
          },
          {
            description: 'Technology Corridor',
            distanceMeters: 10516,
            duration: '1310s',
            polyline: {
              encodedPolyline: 'whanDo`t~M_alt',
            },
            legs: [
              {
                steps: [
                  {
                    distanceMeters: 800,
                    staticDuration: '100s',
                    navigationInstruction: {
                      maneuver: 'DEPART',
                      instructions: 'Head north on Nandankanan Rd',
                    },
                  },
                ],
              },
            ],
          },
        ],
      };

      let capturedUrl = '';
      let capturedHeaders: Record<string, string> = {};
      let capturedBody: any = null;

      global.fetch = jest.fn().mockImplementation((url, opts) => {
        capturedUrl = url.toString();
        capturedHeaders = opts.headers;
        capturedBody = JSON.parse(opts.body);
        return Promise.resolve({
          ok: true,
          status: 200,
          json: async () => mockRoutesApiResponse,
        });
      });

      const result = await provider.calculateRoute(origin, destination, [], 'FASTEST');

      // Verify endpoint and headers
      expect(capturedUrl).toBe('https://routes.googleapis.com/directions/v2:computeRoutes');
      expect(capturedHeaders['X-Goog-Api-Key']).toBe('test-api-key-12345');
      expect(capturedHeaders['X-Goog-FieldMask']).toContain('routes.duration');
      expect(capturedHeaders['X-Goog-FieldMask']).toContain('routes.distanceMeters');
      expect(capturedHeaders['X-Goog-FieldMask']).toContain('routes.polyline.encodedPolyline');
      expect(capturedHeaders['X-Goog-FieldMask']).toContain('routes.legs.steps');

      // Verify request payload specifies motorcycle routing
      expect(capturedBody.travelMode).toBe('TWO_WHEELER');
      expect(capturedBody.origin.location.latLng.latitude).toBe(20.2961);
      expect(capturedBody.destination.location.latLng.latitude).toBe(20.3533);
      expect(capturedBody.computeAlternativeRoutes).toBe(true);

      // Verify canonical route mapping
      expect(result).toBeDefined();
      expect(result.distanceKm).toBe(7.47);
      expect(result.durationMinutes).toBe(18); // 1087s / 60 = 18.1 -> 18 min
      expect(result.provider).toBe('GOOGLE_MAPS');
      expect(result.routeName).toBe('Nandankanan Rd');
      expect(result.steps.length).toBe(2);

      expect(result.steps[0].instruction).toBe('Head north on Nandankanan Rd');
      expect(result.steps[0].type).toBe('DEPART');
      expect(result.steps[0].distanceMeters).toBe(500);

      expect(result.steps[1].instruction).toBe('Turn left onto KIIT Rd');
      expect(result.steps[1].type).toBe('TURN_LEFT');

      // Verify alternative routes
      expect(result.alternatives).toBeDefined();
      expect(result.alternatives!.length).toBe(1);
      expect(result.alternatives![0].distanceKm).toBe(10.52);
      expect(result.alternatives![0].routeName).toBe('Technology Corridor');
    });

    it('should handle 401/403 authorization error safely without exposing secret', async () => {
      mockConfigService.get.mockReturnValue('test-api-key-12345');
      global.fetch = jest.fn().mockResolvedValue({
        ok: false,
        status: 403,
        text: async () => 'API key expired or restricted',
      });

      await expect(provider.calculateRoute(origin, destination)).rejects.toThrow(
        ServiceUnavailableException,
      );
    });

    it('should handle 429 quota/rate limit error', async () => {
      mockConfigService.get.mockReturnValue('test-api-key-12345');
      global.fetch = jest.fn().mockResolvedValue({
        ok: false,
        status: 429,
        text: async () => 'Quota exceeded',
      });

      await expect(provider.calculateRoute(origin, destination)).rejects.toThrow(
        HttpException,
      );
    });

    it('should handle empty routes with NotFoundException', async () => {
      mockConfigService.get.mockReturnValue('test-api-key-12345');
      global.fetch = jest.fn().mockResolvedValue({
        ok: true,
        status: 200,
        json: async () => ({ routes: [] }),
      });

      await expect(provider.calculateRoute(origin, destination)).rejects.toThrow(
        NotFoundException,
      );
    });
  });
});
