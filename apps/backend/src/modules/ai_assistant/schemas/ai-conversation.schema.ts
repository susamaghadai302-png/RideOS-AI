import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type AiConversationDocument = AiConversation & Document;

@Schema({ _id: false })
export class AiChatMessageItem {
  @Prop({ required: true })
  id: string;

  @Prop({ required: true, enum: ['user', 'assistant', 'system'] })
  role: string;

  @Prop({ required: true })
  text: string;

  @Prop({ required: false })
  suggestedAction?: string;

  @Prop({ required: false })
  confidence?: number;

  @Prop({ required: false })
  language?: string;

  @Prop({ required: true, default: () => new Date() })
  timestamp: Date;
}

@Schema({ timestamps: true })
export class AiConversation {
  @Prop({ required: true, unique: true, index: true })
  conversationId: string;

  @Prop({ required: true, index: true })
  riderId: string;

  @Prop({ required: true, default: 'Riding Assistant Session' })
  title: string;

  @Prop({ type: [AiChatMessageItem], default: [] })
  messages: AiChatMessageItem[];

  @Prop({ required: true, default: true })
  isActive: boolean;
}

export const AiConversationSchema = SchemaFactory.createForClass(AiConversation);
AiConversationSchema.index({ riderId: 1, createdAt: -1 });

