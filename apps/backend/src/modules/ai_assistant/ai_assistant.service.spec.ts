import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { AiAssistantService } from './ai_assistant.service';

describe('AiAssistantService', () => {
  let service: AiAssistantService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AiAssistantService,
        {
          provide: ConfigService,
          useValue: {
            get: jest.fn().mockReturnValue(null),
          },
        },
      ],
    }).compile();

    service = module.get<AiAssistantService>(AiAssistantService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should process fuel query and suggest OPEN_NAVIGATION action', async () => {
    const result = await service.processQuery({ prompt: 'Where can I get fuel?' });
    expect(result.response).toContain('gas station');
    expect(result.suggestedAction).toEqual('OPEN_NAVIGATION');
  });

  it('should process weather query and suggest WEATHER_WARNING action', async () => {
    const result = await service.processQuery({ prompt: 'Is it going to rain?' });
    expect(result.response).toContain('Clear skies');
    expect(result.suggestedAction).toEqual('WEATHER_WARNING');
  });
});
