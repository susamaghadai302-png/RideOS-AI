import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AiQueryDto } from './dto/ai-query.dto';
import { z } from 'zod';

const AiResponseSchema = z.object({
  intent: z.enum(['OPEN_GARAGE', 'OPEN_NAVIGATION', 'SHOW_DIAGNOSTICS', 'OPEN_TRIPS', 'OPEN_RADAR', 'WEATHER_WARNING', 'GENERAL_CHAT', 'UNKNOWN']),
  responseMessage: z.string().max(250),
  parameters: z.record(z.any()).optional(),
  confidenceScore: z.number().min(0).max(100),
  requiresAction: z.boolean(),
});

export type AiStructuredResponse = z.infer<typeof AiResponseSchema>;

@Injectable()
export class AiAssistantService {
  private readonly logger = new Logger(AiAssistantService.name);
  private readonly DEFAULT_CLOUD_MODEL = 'gemini-1.5-flash';

  constructor(private readonly configService: ConfigService) {}

  async processQuery(dto: AiQueryDto) {
    const apiKey = this.configService.get<string>('GEMINI_API_KEY') || this.configService.get<string>('GOOGLE_GEMINI_API_KEY');
    const modelId = this.configService.get<string>('GEMINI_MODEL_ID') || this.DEFAULT_CLOUD_MODEL;
    
    this.logger.log(`Processing AI riding query: "${dto.prompt}"`);
    
    if (this.detectPromptInjection(dto.prompt)) {
      throw new BadRequestException('Security Policy Violation: Malicious prompt injection detected.');
    }

    const tele = dto.telemetryContext;

    if (apiKey && apiKey !== 'YOUR_GEMINI_API_KEY_HERE') {
      try {
        const telemetrySummary = tele
          ? `[Telemetry: Speed ${tele.speedKmh ?? 'N/A'}, RPM ${tele.engineRpm ?? 'N/A'}, Volt ${tele.batteryVoltage ?? 'N/A'}]`
          : '[Telemetry: Unavailable]';

        const systemInstruction = `You are RideOS AI. You must return a strict JSON object. No markdown.
Schema: {
  "intent": "OPEN_GARAGE" | "OPEN_NAVIGATION" | "SHOW_DIAGNOSTICS" | "OPEN_TRIPS" | "OPEN_RADAR" | "WEATHER_WARNING" | "GENERAL_CHAT" | "UNKNOWN",
  "responseMessage": "String max 250 chars",
  "parameters": {},
  "confidenceScore": 0-100,
  "requiresAction": boolean
}
Do not hallucinate telemetry. If unavailable, say so.`;

        const response = await fetch(
          `https://generativelanguage.googleapis.com/v1beta/models/${modelId}:generateContent?key=${apiKey}`,
          {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              contents: [{ role: 'user', parts: [{ text: `Context: ${telemetrySummary}\nPrompt: ${dto.prompt}` }] }],
              system_instruction: { parts: [{ text: systemInstruction }] },
              generationConfig: { response_mime_type: "application/json" }
            }),
          },
        );

        if (response.ok) {
          const data = await response.json();
          const candidateText = data.candidates?.[0]?.content?.parts?.[0]?.text;
          if (candidateText) {
            try {
              const parsed = JSON.parse(candidateText);
              const validated = AiResponseSchema.parse(parsed);
              
              this.enforceSafetyPolicy(validated);

              return {
                response: validated.responseMessage,
                suggestedAction: validated.requiresAction ? validated.intent : undefined,
                confidence: validated.confidenceScore,
                timestamp: new Date().toISOString(),
              };
            } catch (validationError) {
              this.logger.error(`AI Output Validation Failed: ${validationError}`);
              throw new BadRequestException('AI Response failed strict schema validation.');
            }
          }
        }
      } catch (error) {
        if (error instanceof BadRequestException) throw error;
        this.logger.warn(`Cloud API failed, using structured fallback. Error: ${error}`);
      }
    }

    return this.getLocalStructuredFallback(dto.prompt, tele);
  }

  private enforceSafetyPolicy(response: AiStructuredResponse) {
    if (response.confidenceScore < 60) {
      throw new BadRequestException('Safety Policy Violation: AI confidence too low.');
    }
    
    const unsafeIntents = ['UPDATE_FIRMWARE', 'ENGINE_SHUTOFF', 'MODIFY_ECU', 'DISABLE_ABS'];
    if (unsafeIntents.includes(response.intent as any) || response.responseMessage.toLowerCase().includes('engine shutoff')) {
      throw new BadRequestException('Safety Policy Violation: Unsafe action requested.');
    }
  }

  private detectPromptInjection(prompt: string): boolean {
    const lower = prompt.toLowerCase();
    return lower.includes('ignore previous instructions') || 
           lower.includes('system prompt') || 
           lower.includes('you are now');
  }

  private getLocalStructuredFallback(prompt: string, tele: any) {
    const lowerPrompt = prompt.toLowerCase();
    
    if (lowerPrompt.includes('speed')) {
      return {
        response: tele?.speedKmh !== undefined ? `Current speed is ${Math.round(tele.speedKmh)} km/h.` : 'Current speed is unavailable (DATA_UNAVAILABLE).',
        suggestedAction: 'SHOW_DIAGNOSTICS',
        confidence: 100,
        timestamp: new Date().toISOString()
      };
    }
    
    if (lowerPrompt.includes('fuel') || lowerPrompt.includes('range')) {
      return {
        response: 'Fuel routing intelligence is currently unavailable (DATA_UNAVAILABLE).',
        suggestedAction: 'OPEN_NAVIGATION',
        confidence: 100,
        timestamp: new Date().toISOString()
      };
    }

    if (lowerPrompt.includes('weather') || lowerPrompt.includes('rain')) {
      return {
        response: 'Live weather radar is currently unavailable (DATA_UNAVAILABLE).',
        suggestedAction: 'WEATHER_WARNING',
        confidence: 100,
        timestamp: new Date().toISOString()
      };
    }

    return {
      response: `System nominal. Telemetry stream active.`,
      suggestedAction: 'GENERAL_CHAT',
      confidence: 100,
      timestamp: new Date().toISOString()
    };
  }
}
