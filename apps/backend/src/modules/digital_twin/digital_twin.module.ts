import { Module } from '@nestjs/common';
import { DigitalTwinController } from './digital_twin.controller';
import { DigitalTwinService } from './digital_twin.service';

@Module({
  controllers: [DigitalTwinController],
  providers: [DigitalTwinService],
  exports: [DigitalTwinService],
})
export class DigitalTwinModule {}
