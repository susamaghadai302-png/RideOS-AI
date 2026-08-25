import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { AiAssistantService } from './ai_assistant.service';
import { AiQueryDto } from './dto/ai-query.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('ai/assistant')
@UseGuards(JwtAuthGuard)
export class AiAssistantController {
  constructor(private readonly aiService: AiAssistantService) {}

  @Post('query')
  async queryAssistant(@Body() dto: AiQueryDto) {
    return this.aiService.processQuery(dto);
  }
}
