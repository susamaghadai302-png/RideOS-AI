import { Module } from '@nestjs/common';
import { RideHistoryController } from './ride_history.controller';
import { RideHistoryService } from './ride_history.service';

@Module({
  controllers: [RideHistoryController],
  providers: [RideHistoryService],
  exports: [RideHistoryService],
})
export class RideHistoryModule {}
