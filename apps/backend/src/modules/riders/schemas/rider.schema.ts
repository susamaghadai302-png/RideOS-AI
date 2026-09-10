import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type RiderDocument = Rider & Document;

@Schema()
export class EmergencyContact {
  @Prop({ required: true })
  name: string;

  @Prop({ required: true })
  phone: string;

  @Prop({ required: true })
  relation: string;
}

const EmergencyContactSchema = SchemaFactory.createForClass(EmergencyContact);

@Schema()
export class Motorcycle {
  @Prop({ required: true })
  bikeId: string;

  @Prop({ required: true })
  make: string;

  @Prop({ required: true })
  model: string;

  @Prop({ required: true })
  year: number;

  @Prop({ required: true })
  engineCC: number;

  @Prop({ default: 45.0 })
  maxLeanAngleLimit: number;

  @Prop({ default: false })
  isPrimary: boolean;
}

const MotorcycleSchema = SchemaFactory.createForClass(Motorcycle);

@Schema()
export class RiderPreferences {
  @Prop({ default: 'SCENIC_TWISTY' })
  routingPreference: string;

  @Prop({ default: true })
  voiceAlertsEnabled: boolean;

  @Prop({ default: 15 })
  sosAutoDispatchDelaySeconds: number;

  @Prop({ default: 'METRIC' })
  units: string;
}

const RiderPreferencesSchema = SchemaFactory.createForClass(RiderPreferences);

@Schema({ timestamps: true })
export class Rider {
  @Prop({ required: false, unique: true, sparse: true, index: true })
  email: string;

  @Prop({ required: true })
  passwordHash: string;

  @Prop({ required: true })
  fullName: string;

  @Prop({ required: true })
  phone: string;

  @Prop({ type: [EmergencyContactSchema], default: [] })
  emergencyContacts: EmergencyContact[];

  @Prop({ type: [MotorcycleSchema], default: [] })
  garage: Motorcycle[];

  @Prop({ type: RiderPreferencesSchema, default: () => ({}) })
  preferences: RiderPreferences;
}

export const RiderSchema = SchemaFactory.createForClass(Rider);
