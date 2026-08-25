import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type MaintenanceRecordDocument = MaintenanceRecord & Document;

@Schema({ timestamps: true })
export class MaintenanceRecord {
  @Prop({ required: true, index: true })
  vehicleId: string;

  @Prop({ required: true, index: true })
  riderId: string;

  @Prop({ required: true })
  serviceType: string;

  @Prop({ required: true, default: Date.now })
  date: Date;

  @Prop({ required: true })
  odometerKm: number;

  @Prop({ default: true })
  isVehicleOdometer: boolean; // true = from vehicle telemetry, false = user entered

  @Prop({ default: '' })
  notes: string;

  @Prop({ default: 0 })
  cost: number;

  @Prop({ default: '' })
  serviceProvider: string;

  @Prop({ type: [String], default: [] })
  attachments: string[]; // URLs or storage keys for invoice, receipt, photos

  @Prop()
  nextDueDate?: Date;

  @Prop()
  nextDueOdometerKm?: number;
}

export const MaintenanceRecordSchema = SchemaFactory.createForClass(MaintenanceRecord);
MaintenanceRecordSchema.index({ vehicleId: 1, date: -1 });
MaintenanceRecordSchema.index({ riderId: 1, date: -1 });
