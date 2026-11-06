import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type AiMemoryDocument = AiMemory & Document;

export type MemoryCategory = 'RIDING_STYLE' | 'VEHICLE_PREF' | 'ROUTE_PREF' | 'SAFETY_NOTE' | 'GENERAL';
export type MemorySource = 'USER_EXPLICIT' | 'INFERRED' | 'VEHICLE_LOG';

@Schema({ timestamps: true })
export class AiMemory {
  @Prop({ required: true, unique: true, index: true })
  memoryId: string;

  @Prop({ required: true, index: true })
  riderId: string;

  @Prop({ required: true })
  key: string;

  @Prop({ required: true })
  value: string;

  @Prop({ required: true, default: 'GENERAL' })
  category: MemoryCategory;

  @Prop({ required: true, default: 'USER_EXPLICIT' })
  source: MemorySource;

  @Prop({ required: true, default: true })
  isConsentGranted: boolean;

  @Prop({ required: true, default: 365 })
  retentionDays: number;

  @Prop({ required: true, default: () => new Date() })
  lastAccessedAt: Date;
}

export const AiMemorySchema = SchemaFactory.createForClass(AiMemory);
AiMemorySchema.index({ riderId: 1, key: 1 }, { unique: true });

