import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { CalculateRouteDto, GeoPointDto } from './dto/calculate-route.dto';
import { ReportHazardDto } from './dto/report-hazard.dto';
import { Hazard, HazardDocument } from './schemas/hazard.schema';
import { OsrmRoutingProvider } from './providers/osrm-routing.provider';
import { MapboxRoutingProvider } from './providers/mapbox-routing.provider';
import { GoogleMapsRoutingProvider } from './providers/google-maps-routing.provider';
import { ScenicRoutingService } from './services/scenic-routing.service';
import { RouteRecalculationService } from './services/route-recalculation.service';
import { RouteResult } from './providers/map-provider.interface';

@Injectable()
export class NavigationService {
  constructor(
    @InjectModel(Hazard.name) private readonly hazardModel: Model<HazardDocument>,
    private readonly osrmProvider: OsrmRoutingProvider,
    private readonly mapboxProvider: MapboxRoutingProvider,
    private readonly googleMapsProvider: GoogleMapsRoutingProvider,
    private readonly scenicService: ScenicRoutingService,
    private readonly recalculationService: RouteRecalculationService,
  ) {}

  async calculateRoute(dto: CalculateRouteDto): Promise<RouteResult> {
    let provider = this.osrmProvider;
    if (dto.provider === 'MAPBOX') {
      provider = this.mapboxProvider as any;
    } else if (dto.provider === 'GOOGLE_MAPS') {
      provider = this.googleMapsProvider as any;
    }

    const baseRoute = await provider.calculateRoute(
      dto.origin,
      dto.destination,
      dto.waypoints || [],
      dto.preference || 'SCENIC_TWISTY',
    );

    return this.scenicService.applyMotorcycleOptimization(baseRoute);
  }

  async reportHazard(reporterId: string, dto: ReportHazardDto): Promise<HazardDocument> {
    const newHazard = new this.hazardModel({
      reporterId,
      type: dto.type,
      severity: dto.severity,
      location: {
        type: 'Point',
        coordinates: [dto.location.lng, dto.location.lat],
      },
      description: dto.description,
    });
    return newHazard.save();
  }

  async findNearbyHazards(lat: number, lng: number, radiusMeters: number = 5000) {
    return this.hazardModel.find({
      isActive: true,
      location: {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [lng, lat],
          },
          $maxDistance: radiusMeters,
        },
      },
    }).exec();
  }

  checkOffRoute(currentLocation: GeoPointDto, waypoints: GeoPointDto[]) {
    const isOff = this.recalculationService.isOffRoute(currentLocation, waypoints);
    return { isOffRoute: isOff };
  }
}
