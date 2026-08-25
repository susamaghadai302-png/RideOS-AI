import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import mongoose, { Document, Types } from 'mongoose';

export type TelemetrySampleDocument = TelemetrySample & Document;

// Reusable schema for individual telemetry fields
@Schema({ _id: false })
export class TelemetryValue {
  @Prop({ type: mongoose.Schema.Types.Mixed })
  value: any;

  @Prop()
  unit: string;

  @Prop({ required: true })
  available: boolean;

  @Prop({ default: 'vehicle' })
  source: string;

  @Prop({ required: true })
  timestamp: Date;
}
const TelemetryValueSchema = SchemaFactory.createForClass(TelemetryValue);

@Schema({ timestamps: true })
export class TelemetrySample {
  @Prop({ required: true })
  sessionId: string;

  @Prop({ required: true })
  vehicleId: string;

  @Prop({ required: true })
  timestamp: Date;

  @Prop({ type: TelemetryValueSchema })
  speed: TelemetryValue;

  @Prop({ type: TelemetryValueSchema })
  rpm: TelemetryValue;

  @Prop({ type: TelemetryValueSchema })
  engineTemperature: TelemetryValue;

  @Prop({ type: TelemetryValueSchema })
  batteryVoltage: TelemetryValue;

  @Prop({ type: TelemetryValueSchema })
  batteryPercentage: TelemetryValue;

  @Prop({ type: TelemetryValueSchema })
  fuelLevel: TelemetryValue;

  @Prop({ type: TelemetryValueSchema })
  odometer: TelemetryValue;

  @Prop({ type: TelemetryValueSchema })
  tripDistance: TelemetryValue;

  @Prop({ type: TelemetryValueSchema })
  gear: TelemetryValue;

  @Prop({ type: TelemetryValueSchema })
  engineState: TelemetryValue;

  @Prop({ type: TelemetryValueSchema })
  ignitionState: TelemetryValue;

  @Prop({ type: TelemetryValueSchema })
  brakeState: TelemetryValue;

  @Prop({ type: TelemetryValueSchema })
  indicatorLeft: TelemetryValue;

  @Prop({ type: TelemetryValueSchema })
  indicatorRight: TelemetryValue;

  @Prop({ type: TelemetryValueSchema })
  headlight: TelemetryValue;

  @Prop({ type: TelemetryValueSchema })
  abs: TelemetryValue;

  @Prop({ type: TelemetryValueSchema })
  tractionControl: TelemetryValue;

  @Prop({ type: TelemetryValueSchema })
  ridingMode: TelemetryValue;

  @Prop({ type: TelemetryValueSchema })
  chargingState: TelemetryValue;

  @Prop({ type: TelemetryValueSchema })
  gps: TelemetryValue;

  @Prop({ type: TelemetryValueSchema })
  deviceVoltage: TelemetryValue;

  @Prop({ type: TelemetryValueSchema })
  faultCodes: TelemetryValue;

  @Prop({ type: TelemetryValueSchema })
  connectionQuality: TelemetryValue;
}

export const TelemetrySampleSchema = SchemaFactory.createForClass(TelemetrySample);
