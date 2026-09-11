import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { DiagnosticsController } from './diagnostics.controller';
import { DiagnosticsService } from './diagnostics.service';
import { DiagnosticsDecoder } from './diagnostics.decoder';
import { DiagnosticScan, DiagnosticScanSchema } from './schemas/diagnostic-scan.schema';
import { VehiclesModule } from '../vehicles/vehicles.module';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: DiagnosticScan.name, schema: DiagnosticScanSchema }]),
    VehiclesModule,
  ],
  controllers: [DiagnosticsController],
  providers: [DiagnosticsService, DiagnosticsDecoder],
  exports: [DiagnosticsService],
})
export class DiagnosticsModule {}
