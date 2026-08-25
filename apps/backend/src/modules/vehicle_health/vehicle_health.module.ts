import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { DiagnosticEvent, DiagnosticEventSchema } from './schemas/diagnostic_event.schema';
import { MaintenanceRecord, MaintenanceRecordSchema } from './schemas/maintenance_record.schema';
import { VehicleAlert, VehicleAlertSchema } from './schemas/vehicle_alert.schema';
import { VehicleDocument, VehicleDocumentSchema } from './schemas/vehicle_document.schema';
import { VehicleHealthService } from './vehicle_health.service';
import { VehicleHealthController } from './vehicle_health.controller';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: DiagnosticEvent.name, schema: DiagnosticEventSchema },
      { name: MaintenanceRecord.name, schema: MaintenanceRecordSchema },
      { name: VehicleAlert.name, schema: VehicleAlertSchema },
      { name: VehicleDocument.name, schema: VehicleDocumentSchema },
    ]),
  ],
  controllers: [VehicleHealthController],
  providers: [VehicleHealthService],
  exports: [VehicleHealthService],
})
export class VehicleHealthModule {}
