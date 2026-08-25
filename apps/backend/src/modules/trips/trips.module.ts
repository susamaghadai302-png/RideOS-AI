import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { Trip, TripSchema } from './schemas/trip.schema';
import { SavedPlace, SavedPlaceSchema } from './schemas/saved_place.schema';
import { TripsService } from './trips.service';
import { TripsController } from './trips.controller';
import { SavedPlacesService } from './saved_places.service';
import { SavedPlacesController } from './saved_places.controller';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Trip.name, schema: TripSchema },
      { name: SavedPlace.name, schema: SavedPlaceSchema },
    ]),
  ],
  controllers: [TripsController, SavedPlacesController],
  providers: [TripsService, SavedPlacesService],
  exports: [TripsService, SavedPlacesService],
})
export class TripsModule {}
