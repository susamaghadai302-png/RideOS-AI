import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type GarageVehicleDocument = GarageVehicle & Document;

@Schema()
export class VehicleConfiguration {
  @Prop({ default: 'standard' })
  paintColor: string;

  @Prop({ default: 'oem' })
  exhaustSystem: string;

  @Prop({ default: 'oem' })
  wheels: string;

  @Prop({ default: 'standard' })
  seat: string;

  @Prop({ default: 'street' })
  rideMode: string;

  @Prop({ type: Object, default: {} })
  accessories: Record<string, boolean>;
}

const VehicleConfigurationSchema = SchemaFactory.createForClass(VehicleConfiguration);

@Schema({ timestamps: true })
export class GarageVehicle {
  @Prop({ required: true, index: true })
  riderId: string;

  @Prop({ required: true })
  vehicleId: string; // references predefined vehicle keys e.g. 'yamaha_r1m_2024'

  @Prop({ required: true })
  make: string;

  @Prop({ required: true })
  model: string;

  @Prop({ required: true })
  year: number;

  @Prop({ default: false })
  isPrimary: boolean;

  @Prop({ type: VehicleConfigurationSchema, default: () => ({}) })
  configuration: VehicleConfiguration;

  @Prop({ type: Object, default: {} })
  telemetryMetrics: Record<string, any>;
}

export const GarageVehicleSchema = SchemaFactory.createForClass(GarageVehicle);
