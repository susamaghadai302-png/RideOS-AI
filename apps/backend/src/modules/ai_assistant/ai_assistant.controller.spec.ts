import { Test, TestingModule } from '@nestjs/testing';
import { UnauthorizedException } from '@nestjs/common';
import { AiAssistantController } from './ai_assistant.controller';
import { AiAssistantService } from './ai_assistant.service';

describe('AiAssistantController - Authentication & Data Isolation Tests', () => {
  let controller: AiAssistantController;
  let mockAiService: any;

  beforeEach(async () => {
    mockAiService = {
      processQuery: jest.fn().mockResolvedValue({ response: 'ok', confidence: 100 }),
      getProviderStatus: jest.fn().mockReturnValue({ status: 'CONNECTED' }),
      getConversations: jest.fn().mockResolvedValue([]),
      getConversation: jest.fn().mockResolvedValue({ conversationId: 'c1' }),
      deleteConversation: jest.fn().mockResolvedValue({ success: true }),
      getMemories: jest.fn().mockResolvedValue([]),
      createOrUpdateMemory: jest.fn().mockResolvedValue({ memoryId: 'm1' }),
      updateMemory: jest.fn().mockResolvedValue({ memoryId: 'm1' }),
      deleteMemory: jest.fn().mockResolvedValue({ success: true }),
      clearAllMemories: jest.fn().mockResolvedValue({ success: true, count: 2 }),
      listKnowledgeDocs: jest.fn().mockResolvedValue([]),
      searchKnowledge: jest.fn().mockResolvedValue([]),
      createKnowledgeDoc: jest.fn().mockResolvedValue({ docId: 'k1' }),
      deleteKnowledgeDoc: jest.fn().mockResolvedValue({ success: true }),
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [AiAssistantController],
      providers: [
        {
          provide: AiAssistantService,
          useValue: mockAiService,
        },
      ],
    }).compile();

    controller = module.get<AiAssistantController>(AiAssistantController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  describe('User Authentication & Tenant Isolation', () => {
    it('should extract riderId from req.user.userId', async () => {
      const req = { user: { userId: 'rider-abc' } };
      await controller.queryAssistant({ prompt: 'check tires' }, req);
      expect(mockAiService.processQuery).toHaveBeenCalledWith(
        { prompt: 'check tires' },
        'rider-abc',
      );
    });

    it('should extract riderId from req.user.sub if userId is absent', async () => {
      const req = { user: { sub: 'rider-sub-123' } };
      await controller.getConversations(req);
      expect(mockAiService.getConversations).toHaveBeenCalledWith('rider-sub-123');
    });

    it('should throw UnauthorizedException when token payload lacks rider identification', async () => {
      const reqEmpty = { user: {} };
      await expect(
        controller.queryAssistant({ prompt: 'check tires' }, reqEmpty),
      ).rejects.toThrow(UnauthorizedException);

      const reqNoUser = {};
      await expect(controller.getMemories(reqNoUser)).rejects.toThrow(
        UnauthorizedException,
      );
    });

    it('should strictly scope memory operations to authenticated rider', async () => {
      const req = { user: { userId: 'rider-secure-01' } };
      await controller.getMemories(req);
      expect(mockAiService.getMemories).toHaveBeenCalledWith('rider-secure-01');

      await controller.deleteMemory('mem-99', req);
      expect(mockAiService.deleteMemory).toHaveBeenCalledWith('rider-secure-01', 'mem-99');

      await controller.clearAllMemories(req);
      expect(mockAiService.clearAllMemories).toHaveBeenCalledWith('rider-secure-01');
    });

    it('should reject unauthenticated knowledge management mutations', async () => {
      const reqNoUser = {};
      await expect(
        controller.createKnowledge(
          { vehicleModel: 'S1000RR', title: 'Tires', content: 'Specs' },
          reqNoUser,
        ),
      ).rejects.toThrow(UnauthorizedException);

      await expect(
        controller.deleteKnowledge('doc-1', reqNoUser),
      ).rejects.toThrow(UnauthorizedException);
    });
  });
});
