import { Module } from '@nestjs/common';
import { TelematicsController } from './telematics.controller';
import { TelematicsService } from './telematics.service';
import { TelemetryBatchWriterService } from './services/telemetry-batch-writer.service';
import { LeanAngleCalculatorService } from './services/lean-angle-calculator.service';

@Module({
  controllers: [TelematicsController],
  providers: [
    TelematicsService,
    TelemetryBatchWriterService,
    LeanAngleCalculatorService,
  ],
  exports: [TelematicsService, LeanAngleCalculatorService],
})
export class TelematicsModule {}
