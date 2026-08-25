import { Module } from '@nestjs/common';
import { AiAssistantController } from './ai_assistant.controller';
import { AiAssistantService } from './ai_assistant.service';

@Module({
  controllers: [AiAssistantController],
  providers: [AiAssistantService],
  exports: [AiAssistantService],
})
export class AiAssistantModule {}
