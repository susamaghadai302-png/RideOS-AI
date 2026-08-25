import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type SavedPlaceDocument = SavedPlace & Document;

@Schema({ timestamps: true })
export class SavedPlace {
  @Prop({ required: true, index: true })
  riderId: string;

  @Prop({ required: true })
  name: string;

  @Prop({ required: true, default: 'FAVORITE' })
  category: string; // 'HOME' | 'WORK' | 'FAVORITE' | 'CUSTOM'

  @Prop({ required: true })
  lat: number;

  @Prop({ required: true })
  lng: number;

  @Prop({ default: '' })
  address: string;

  @Prop({ default: 'place' })
  icon: string;
}

export const SavedPlaceSchema = SchemaFactory.createForClass(SavedPlace);
SavedPlaceSchema.index({ riderId: 1, name: 1 });
