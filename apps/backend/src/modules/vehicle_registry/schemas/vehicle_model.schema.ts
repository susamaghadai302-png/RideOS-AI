import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type VehicleModelDocument = VehicleModel & Document;

@Schema({ timestamps: true })
export class VehicleModel {
  @Prop({ required: true })
  manufacturer: string;

  @Prop({ required: true })
  model: string;

  @Prop()
  variant: string;

  @Prop({ required: true })
  year: number;

  @Prop({ required: true })
  category: string; // e.g. Scooter, Superbike, Adventure

  @Prop()
  engineType: string;

  @Prop()
  fuelType: string; // e.g. Petrol, Electric, Hybrid

  @Prop({ type: [String], default: [] })
  bluetoothIdentifiers: string[]; // Known MAC prefixes or advertised names

  @Prop({ type: Object, default: {} })
  bleServices: Record<string, any>; // Expected GATT services

  @Prop({ required: true })
  protocolAdapter: string; // ID of the parser to use (e.g. 'generic_obd', 'ducati_v1', 'suzuki_snet')

  @Prop({ type: [String], default: [] })
  supportedFunctions: string[]; // e.g. ['read_speed', 'read_battery', 'remote_start']

  @Prop()
  model3DUrl: string; // Remote URL to GLB asset

  @Prop()
  thumbnailUrl: string;

  @Prop({ type: Object, default: {} })
  specifications: Record<string, any>;

  @Prop({ type: Object, default: {} })
  maintenanceIntervals: Record<string, any>;
}

export const VehicleModelSchema = SchemaFactory.createForClass(VehicleModel);
