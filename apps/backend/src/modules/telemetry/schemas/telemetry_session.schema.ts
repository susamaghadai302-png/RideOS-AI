import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type TelemetrySessionDocument = TelemetrySession & Document;

@Schema({ timestamps: true })
export class TelemetrySession {
  @Prop({ required: true })
  vehicleId: string;

  @Prop({ required: true })
  startTime: Date;

  @Prop()
  endTime: Date;

  @Prop({ default: 0 })
  distanceKm: number;

  @Prop({ default: 0 })
  maxSpeedKmh: number;

  @Prop({ default: 0 })
  averageSpeedKmh: number;
}

export const TelemetrySessionSchema = SchemaFactory.createForClass(TelemetrySession);
