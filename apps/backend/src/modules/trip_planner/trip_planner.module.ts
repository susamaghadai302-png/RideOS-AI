import { Module } from '@nestjs/common';
import { TripPlannerController } from './trip_planner.controller';
import { TripPlannerService } from './trip_planner.service';

@Module({
  controllers: [TripPlannerController],
  providers: [TripPlannerService],
  exports: [TripPlannerService],
})
export class TripPlannerModule {}
