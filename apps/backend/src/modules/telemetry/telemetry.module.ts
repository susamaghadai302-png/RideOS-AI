import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { TelemetrySample, TelemetrySampleSchema } from './schemas/telemetry_sample.schema';
import { TelemetrySession, TelemetrySessionSchema } from './schemas/telemetry_session.schema';
import { TelemetryService } from './services/telemetry.service';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: TelemetrySample.name, schema: TelemetrySampleSchema },
      { name: TelemetrySession.name, schema: TelemetrySessionSchema },
    ]),
  ],
  controllers: [],
  providers: [TelemetryService],
  exports: [TelemetryService]
})
export class TelemetryModule {}
