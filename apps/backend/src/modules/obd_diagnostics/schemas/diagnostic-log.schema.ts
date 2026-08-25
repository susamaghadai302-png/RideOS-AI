import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type DiagnosticLogDocument = DiagnosticLog & Document;

@Schema({ timestamps: true })
export class DiagnosticLog {
  @Prop({ required: true, index: true })
  riderId: string;

  @Prop({ required: true })
  rpm: number;

  @Prop({ required: true })
  engineTempC: number;

  @Prop({ required: true })
  throttlePct: number;

  @Prop({ required: true })
  batteryVoltage: number;

  @Prop({ required: true })
  frontTirePsi: number;

  @Prop({ required: true })
  rearTirePsi: number;

  @Prop({ type: [String], default: [] })
  diagnosticCodes: string[];

  @Prop({ default: false })
  tpmsWarning: boolean;

  @Prop()
  tpmsMessage?: string;
}

export const DiagnosticLogSchema = SchemaFactory.createForClass(DiagnosticLog);
