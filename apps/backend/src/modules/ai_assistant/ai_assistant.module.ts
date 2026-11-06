import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AiAssistantController } from './ai_assistant.controller';
import { AiAssistantService } from './ai_assistant.service';
import { AiConversation, AiConversationSchema } from './schemas/ai-conversation.schema';
import { AiMemory, AiMemorySchema } from './schemas/ai-memory.schema';
import { AiKnowledge, AiKnowledgeSchema } from './schemas/ai-knowledge.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: AiConversation.name, schema: AiConversationSchema },
      { name: AiMemory.name, schema: AiMemorySchema },
      { name: AiKnowledge.name, schema: AiKnowledgeSchema },
    ]),
  ],
  controllers: [AiAssistantController],
  providers: [AiAssistantService],
  exports: [AiAssistantService],
})
export class AiAssistantModule {}
