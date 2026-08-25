import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ObdDiagnosticsController } from './obd_diagnostics.controller';
import { ObdDiagnosticsService } from './obd_diagnostics.service';
import { DiagnosticLog, DiagnosticLogSchema } from './schemas/diagnostic-log.schema';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: DiagnosticLog.name, schema: DiagnosticLogSchema }]),
  ],
  controllers: [ObdDiagnosticsController],
  providers: [ObdDiagnosticsService],
  exports: [ObdDiagnosticsService],
})
export class ObdDiagnosticsModule {}
