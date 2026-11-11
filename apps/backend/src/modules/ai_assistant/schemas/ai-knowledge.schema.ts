import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type AiKnowledgeDocument = AiKnowledge & Document;

export type KnowledgeCategory = 'MANUAL' | 'SPECS' | 'MAINTENANCE' | 'SAFETY';

@Schema({ timestamps: true })
export class AiKnowledge {
  @Prop({ required: true, unique: true, index: true })
  docId: string;

  @Prop({ required: true, index: true })
  vehicleModel: string;

  @Prop({ required: true })
  title: string;

  @Prop({ required: true, default: 'MANUAL' })
  category: KnowledgeCategory;

  @Prop({ required: true })
  content: string;

  @Prop({ type: [String], default: [] })
  tags: string[];

  @Prop({ type: [String], default: [] })
  citations: string[];

  @Prop({ required: true, default: true })
  isVerified: boolean;
}

export const AiKnowledgeSchema = SchemaFactory.createForClass(AiKnowledge);
AiKnowledgeSchema.index({ vehicleModel: 1, category: 1 });
AiKnowledgeSchema.index({ content: 'text', title: 'text', tags: 'text' });

