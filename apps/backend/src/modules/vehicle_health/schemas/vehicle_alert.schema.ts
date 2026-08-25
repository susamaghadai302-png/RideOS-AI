import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type VehicleAlertDocument = VehicleAlert & Document;

@Schema({ timestamps: true })
export class VehicleAlert {
  @Prop({ required: true, index: true })
  vehicleId: string;

  @Prop({ required: true, index: true })
  riderId: string;

  @Prop({ required: true })
  alertKey: string;

  @Prop({ required: true })
  title: string;

  @Prop({ required: true })
  message: string;

  @Prop({ required: true, default: 'GENERAL' })
  category: string;

  @Prop({ required: true, default: 'WARNING' })
  severity: string; // 'INFO' | 'NOTICE' | 'WARNING' | 'CRITICAL'

  @Prop({ required: true, default: 'ACTIVE' })
  status: string; // 'NEW' | 'ACTIVE' | 'ACKNOWLEDGED' | 'RESOLVED'

  @Prop({ required: true, default: Date.now })
  firstTriggered: Date;

  @Prop({ required: true, default: Date.now })
  lastTriggered: Date;

  @Prop()
  acknowledgedAt?: Date;

  @Prop()
  resolvedAt?: Date;
}

export const VehicleAlertSchema = SchemaFactory.createForClass(VehicleAlert);
VehicleAlertSchema.index({ vehicleId: 1, status: 1 });
VehicleAlertSchema.index({ riderId: 1, createdAt: -1 });
