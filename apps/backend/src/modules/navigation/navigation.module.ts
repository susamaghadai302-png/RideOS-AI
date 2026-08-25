import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { Hazard, HazardSchema } from './schemas/hazard.schema';
import { NavigationController } from './navigation.controller';
import { NavigationService } from './navigation.service';
import { OsrmRoutingProvider } from './providers/osrm-routing.provider';
import { MapboxRoutingProvider } from './providers/mapbox-routing.provider';
import { GoogleMapsRoutingProvider } from './providers/google-maps-routing.provider';
import { ScenicRoutingService } from './services/scenic-routing.service';
import { RouteRecalculationService } from './services/route-recalculation.service';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Hazard.name, schema: HazardSchema }]),
  ],
  controllers: [NavigationController],
  providers: [
    NavigationService,
    OsrmRoutingProvider,
    MapboxRoutingProvider,
    GoogleMapsRoutingProvider,
    ScenicRoutingService,
    RouteRecalculationService,
  ],
  exports: [NavigationService],
})
export class NavigationModule {}
