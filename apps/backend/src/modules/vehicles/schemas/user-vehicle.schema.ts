import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type UserVehicleDocument = UserVehicle & Document;

@Schema({ timestamps: true })
export class UserVehicle {
  @Prop({ required: true, index: true })
  ownerId: string;

  @Prop()
  masterVehicleId: string; // Reference to Master Data if applicable

  @Prop({ required: true })
  category: string; // e.g., Car, Motorcycle, Scooter, Electric Vehicle

  @Prop({ required: true })
  manufacturer: string;

  @Prop({ required: true })
  model: string;

  @Prop()
  variant: string;

  @Prop({ required: true })
  year: number;

  @Prop({
    sparse: true,
    unique: true, // Only unique where it exists
    validate: {
      validator: function(v: string) {
        return !v || v.length === 17;
      },
      message: 'VIN must be exactly 17 characters'
    }
  })
  vin: string;

  @Prop()
  registrationNumber: string;

  @Prop({ required: true })
  fuelType: string;

  @Prop()
  powertrainType: string;

  // ICE specific
  @Prop()
  engineCc: number;

  @Prop()
  transmission: string;

  // EV specific
  @Prop()
  batteryCapacityKwh: number;

  @Prop()
  rangeKm: number;

  @Prop()
  chargingType: string;

  @Prop()
  color: string;

  @Prop()
  nickname: string;

  @Prop()
  odometer: number;

  @Prop({ default: true })
  isActive: boolean;

  @Prop({ default: false })
  isPrimary: boolean;
}

export const UserVehicleSchema = SchemaFactory.createForClass(UserVehicle);

// Unique VIN per owner - Wait, if we use unique constraint on VIN across all docs, a user can't register someone else's VIN anyway (which is good). But `sparse: true` handles nulls.
