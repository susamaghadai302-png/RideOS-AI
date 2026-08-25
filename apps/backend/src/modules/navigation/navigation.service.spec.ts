import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { getModelToken } from '@nestjs/mongoose';
import { NavigationService } from './navigation.service';
import { Hazard } from './schemas/hazard.schema';
import { OsrmRoutingProvider } from './providers/osrm-routing.provider';
import { MapboxRoutingProvider } from './providers/mapbox-routing.provider';
import { GoogleMapsRoutingProvider } from './providers/google-maps-routing.provider';
import { ScenicRoutingService } from './services/scenic-routing.service';
import { RouteRecalculationService } from './services/route-recalculation.service';

describe('NavigationService', () => {
  let service: NavigationService;

  const mockHazardModel = {
    find: jest.fn(),
  };

  const mockConfigService = {
    get: jest.fn().mockReturnValue(undefined),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        NavigationService,
        {
          provide: getModelToken(Hazard.name),
          useValue: mockHazardModel,
        },
        {
          provide: ConfigService,
          useValue: mockConfigService,
        },
        OsrmRoutingProvider,
        MapboxRoutingProvider,
        GoogleMapsRoutingProvider,
        ScenicRoutingService,
        RouteRecalculationService,
      ],
    }).compile();

    service = module.get<NavigationService>(NavigationService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should calculate a motorcycle scenic route', async () => {
    const result = await service.calculateRoute({
      origin: { lat: 37.7749, lng: -122.4194 },
      destination: { lat: 36.6002, lng: -121.8947 },
      preference: 'SCENIC_TWISTY',
    });

    expect(result).toBeDefined();
    expect(result.distanceKm).toBeGreaterThan(0);
    expect(result.twistinessScore).toBeGreaterThan(0);
  }, 15000);
});
