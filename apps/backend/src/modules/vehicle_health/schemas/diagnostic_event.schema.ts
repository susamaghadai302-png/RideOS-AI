import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type DiagnosticEventDocument = DiagnosticEvent & Document;

@Schema({ timestamps: true })
export class DiagnosticEvent {
  @Prop({ required: true, index: true })
  vehicleId: string;

  @Prop({ required: true, index: true })
  riderId: string;

  @Prop({ required: true })
  code: string; // e.g. 'P0300', 'P0117', 'P0562'

  @Prop({ required: true, default: 'VEHICLE_ECU' })
  source: string; // 'VEHICLE_ECU' | 'OBD2_ADAPTER' | 'BMS' | 'CAN_BUS'

  @Prop({ required: true, default: 'WARNING' })
  severity: string; // 'INFO' | 'NOTICE' | 'WARNING' | 'CRITICAL'

  @Prop({ required: true })
  description: string;

  @Prop({ required: true, default: Date.now })
  firstSeen: Date;

  @Prop({ required: true, default: Date.now })
  lastSeen: Date;

  @Prop({ default: 1 })
  occurrences: number;

  @Prop({ default: true })
  active: boolean;

  @Prop({ default: false })
  resolved: boolean;

  @Prop()
  resolvedAt?: Date;

  @Prop()
  tripId?: string;

  @Prop({ type: Object })
  rawData?: Record<string, any>;
}

export const DiagnosticEventSchema = SchemaFactory.createForClass(DiagnosticEvent);
DiagnosticEventSchema.index({ vehicleId: 1, active: 1 });
DiagnosticEventSchema.index({ riderId: 1, createdAt: -1 });
