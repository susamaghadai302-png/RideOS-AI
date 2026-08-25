import { Controller, Get, Param } from '@nestjs/common';
import { RideHistoryService } from './ride_history.service';

@Controller('ride-history')
export class RideHistoryController {
  constructor(private readonly rideHistoryService: RideHistoryService) {}

  @Get('rider/:riderId')
  async getRiderHistory(@Param('riderId') riderId: string) {
    return this.rideHistoryService.getHistoryForRider(riderId);
  }
}
