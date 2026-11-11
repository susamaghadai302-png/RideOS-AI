import {
  Controller,
  Post,
  Get,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  Req,
  UseGuards,
  HttpCode,
  HttpStatus,
  UnauthorizedException,
} from '@nestjs/common';
import { AiAssistantService } from './ai_assistant.service';
import { AiQueryDto } from './dto/ai-query.dto';
import { CreateMemoryDto, UpdateMemoryDto } from './dto/memory.dto';
import { CreateKnowledgeDto } from './dto/knowledge.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('ai/assistant')
@UseGuards(JwtAuthGuard)
export class AiAssistantController {
  constructor(private readonly aiService: AiAssistantService) {}

  private getRiderId(req: any): string {
    const riderId = req.user?.userId || req.user?.sub;
    if (!riderId) {
      throw new UnauthorizedException('Rider identity could not be verified from token');
    }
    return riderId;
  }

  @Post('query')
  async queryAssistant(@Body() dto: AiQueryDto, @Req() req: any) {
    const riderId = this.getRiderId(req);
    return this.aiService.processQuery(dto, riderId);
  }

  @Get('status')
  getStatus() {
    return this.aiService.getProviderStatus();
  }

  // ==========================================
  // CONVERSATIONS
  // ==========================================

  @Get('conversations')
  async getConversations(@Req() req: any) {
    const riderId = this.getRiderId(req);
    return this.aiService.getConversations(riderId);
  }

  @Get('conversations/:id')
  async getConversation(@Param('id') conversationId: string, @Req() req: any) {
    const riderId = this.getRiderId(req);
    return this.aiService.getConversation(riderId, conversationId);
  }

  @Delete('conversations/:id')
  async deleteConversation(@Param('id') conversationId: string, @Req() req: any) {
    const riderId = this.getRiderId(req);
    return this.aiService.deleteConversation(riderId, conversationId);
  }

  // ==========================================
  // MEMORIES (USER-CONTROLLED, ACCOUNT ISOLATED)
  // ==========================================

  @Get('memories')
  async getMemories(@Req() req: any) {
    const riderId = this.getRiderId(req);
    return this.aiService.getMemories(riderId);
  }

  @Post('memories')
  async createMemory(@Body() dto: CreateMemoryDto, @Req() req: any) {
    const riderId = this.getRiderId(req);
    return this.aiService.createOrUpdateMemory(riderId, dto);
  }

  @Patch('memories/:id')
  async updateMemory(
    @Param('id') memoryId: string,
    @Body() dto: UpdateMemoryDto,
    @Req() req: any,
  ) {
    const riderId = this.getRiderId(req);
    return this.aiService.updateMemory(riderId, memoryId, dto);
  }

  @Delete('memories/:id')
  async deleteMemory(@Param('id') memoryId: string, @Req() req: any) {
    const riderId = this.getRiderId(req);
    return this.aiService.deleteMemory(riderId, memoryId);
  }

  @Delete('memories')
  @HttpCode(HttpStatus.OK)
  async clearAllMemories(@Req() req: any) {
    const riderId = this.getRiderId(req);
    return this.aiService.clearAllMemories(riderId);
  }

  // ==========================================
  // KNOWLEDGE & RESEARCH MANUALS
  // ==========================================

  @Get('knowledge')
  async listKnowledge(@Query('vehicleModel') vehicleModel?: string) {
    return this.aiService.listKnowledgeDocs(vehicleModel);
  }

  @Get('knowledge/search')
  async searchKnowledge(
    @Query('q') query: string,
    @Query('vehicleModel') vehicleModel?: string,
  ) {
    return this.aiService.searchKnowledge({ query, vehicleModel });
  }

  @Post('knowledge')
  async createKnowledge(@Body() dto: CreateKnowledgeDto, @Req() req: any) {
    this.getRiderId(req);
    return this.aiService.createKnowledgeDoc(dto);
  }

  @Delete('knowledge/:id')
  async deleteKnowledge(@Param('id') docId: string, @Req() req: any) {
    this.getRiderId(req);
    return this.aiService.deleteKnowledgeDoc(docId);
  }
}
