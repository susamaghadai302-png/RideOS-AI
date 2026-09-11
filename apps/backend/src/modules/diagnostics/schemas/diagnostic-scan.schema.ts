import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type DiagnosticScanDocument = DiagnosticScan & Document;

@Schema()
export class DiagnosticFault {
  @Prop({ required: true })
  code: string;

  @Prop({ required: true })
  module: string; // e.g. ECM, ABS

  @Prop({ required: true })
  severity: string;

  @Prop({ type: Object, default: {} })
  freezeFrameSnapshot: Record<string, any>;
}

export const DiagnosticFaultSchema = SchemaFactory.createForClass(DiagnosticFault);

@Schema({ timestamps: true })
export class DiagnosticScan {
  @Prop({ type: Types.ObjectId, ref: 'UserVehicle', required: true, index: true })
  vehicleId: Types.ObjectId;

  @Prop({ required: true, index: true })
  ownerId: string; // To avoid cross-population lookups when filtering

  @Prop()
  scannedVin: string;

  @Prop({ required: true })
  transportType: string;

  @Prop({ required: true })
  protocol: string;

  @Prop({ type: [DiagnosticFaultSchema], default: [] })
  faults: DiagnosticFault[];

  @Prop({ default: false })
  isClearCommand: boolean;
}

export const DiagnosticScanSchema = SchemaFactory.createForClass(DiagnosticScan);
