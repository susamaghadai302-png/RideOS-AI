import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type HazardDocument = Hazard & Document;

@Schema({ timestamps: true })
export class Hazard {
  @Prop({ required: true })
  reporterId: string;

  @Prop({ required: true, enum: ['GRAVEL', 'OIL', 'ACCIDENT', 'CONSTRUCTION', 'POLICE'] })
  type: string;

  @Prop({ required: true, enum: ['LOW', 'MEDIUM', 'HIGH'] })
  severity: string;

  @Prop({
    type: {
      type: String,
      enum: ['Point'],
      required: true,
      default: 'Point',
    },
    coordinates: {
      type: [Number], // [lng, lat]
      required: true,
    },
  })
  location: {
    type: string;
    coordinates: number[];
  };

  @Prop()
  description?: string;

  @Prop({ default: true })
  isActive: boolean;
}

export const HazardSchema = SchemaFactory.createForClass(Hazard);
HazardSchema.index({ location: '2dsphere' });
