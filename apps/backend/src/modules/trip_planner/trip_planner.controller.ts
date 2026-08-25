import { Controller, Post, Body } from '@nestjs/common';
import { TripPlannerService } from './trip_planner.service';

@Controller('trip-planner')
export class TripPlannerController {
  constructor(private readonly tripPlannerService: TripPlannerService) {}

  @Post('generate')
  async generatePlan(
    @Body('title') title: string,
    @Body('originLat') originLat: number,
    @Body('originLng') originLng: number,
    @Body('destLat') destLat: number,
    @Body('destLng') destLng: number,
  ) {
    return this.tripPlannerService.generateTouringPlan(
      title || 'Pacific Coast Touring',
      originLat || 37.7749,
      originLng || -122.4194,
      destLat || 34.0522,
      destLng || -118.2437,
    );
  }
}
