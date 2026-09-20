import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type SosIncidentDocument = SosIncident & Document;

@Schema({ timestamps: true })
export class SosIncident {
  @Prop({ required: true, index: true })
  riderId: string;

  @Prop({ required: true, enum: ['MANUAL', 'AUTOMATIC_IMPACT', 'FALL_DETECTION'] })
  triggerType: string;

  @Prop({ required: true, enum: ['PENDING_COUNTDOWN', 'DISPATCHED', 'CANCELLED', 'RESOLVED'] })
  status: string;

  @Prop({
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point',
    },
    coordinates: {
      type: [Number], // [lng, lat]
    },
  })
  location: {
    type: string;
    coordinates: number[];
  };

  @Prop()
  impactForceG?: number;

  @Prop()
  tripId?: string;

  @Prop()
  dispatchedAt?: Date;
}

export const SosIncidentSchema = SchemaFactory.createForClass(SosIncident);
SosIncidentSchema.index({ location: '2dsphere' });
