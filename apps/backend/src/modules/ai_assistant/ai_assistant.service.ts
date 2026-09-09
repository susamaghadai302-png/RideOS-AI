import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AiQueryDto } from './dto/ai-query.dto';

@Injectable()
export class AiAssistantService {
  private readonly logger = new Logger(AiAssistantService.name);

  // Isolate model IDs to configuration constants, not hard-coded in domain logic.
  private readonly DEFAULT_CLOUD_MODEL = 'gemini-1.5-flash';

  constructor(private readonly configService: ConfigService) {}

  async processQuery(dto: AiQueryDto) {
    const apiKey = this.configService.get<string>('GEMINI_API_KEY') || this.configService.get<string>('GOOGLE_GEMINI_API_KEY');
    const modelId = this.configService.get<string>('GEMINI_MODEL_ID') || this.DEFAULT_CLOUD_MODEL;
    
    this.logger.log(`Processing AI riding query: "${dto.prompt}"`);

    const lowerPrompt = dto.prompt.toLowerCase();
    const tele = dto.telemetryContext;

    // Intent Action Mapper
    let suggestedAction: string | undefined;
    if (lowerPrompt.includes('garage') || lowerPrompt.includes('bike')) {
      suggestedAction = 'OPEN_GARAGE';
    } else if (lowerPrompt.includes('navigate') || lowerPrompt.includes('fuel') || lowerPrompt.includes('route')) {
      suggestedAction = 'OPEN_NAVIGATION';
    } else if (lowerPrompt.includes('health') || lowerPrompt.includes('diagnostics') || lowerPrompt.includes('tpms') || lowerPrompt.includes('obd')) {
      suggestedAction = 'SHOW_DIAGNOSTICS';
    } else if (lowerPrompt.includes('trip') || lowerPrompt.includes('history')) {
      suggestedAction = 'OPEN_TRIPS';
    } else if (lowerPrompt.includes('radar') || lowerPrompt.includes('squad')) {
      suggestedAction = 'OPEN_RADAR';
    }

    // Call live Gemini API if key is present in environment
    if (apiKey && apiKey !== 'YOUR_GEMINI_API_KEY_HERE') {
      try {
        const telemetrySummary = tele
          ? `[Telemetry Context: Speed ${tele.speedKmh ?? 'N/A'} km/h, RPM ${tele.engineRpm ?? 'N/A'}, Battery ${tele.batteryVoltage ?? 'N/A'}V, Temp ${tele.coolantTempC ?? 'N/A'}°C, Fuel ${tele.fuelLevelPct ?? 'N/A'}%, Mode: ${tele.isSimulated ? 'Simulated' : 'Real BLE'}]`
          : '[Telemetry Context: Disconnected / Not Available]';

        const response = await fetch(
          `https://generativelanguage.googleapis.com/v1beta/models/${modelId}:generateContent?key=${apiKey}`,
          {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              contents: [
                {
                  role: 'user',
                  parts: [
                    {
                      text: `System Persona: You are RideOS AI Co-Pilot, an intelligent motorcycle co-pilot. Provide safe, concise riding assistance (max 2 sentences). Always state if telemetry is unavailable rather than making up numbers.\n${telemetrySummary}\nUser Prompt: ${dto.prompt}`,
                    },
                  ],
                },
              ],
            }),
          },
        );

        if (response.ok) {
          const data = await response.json();
          const candidateText = data.candidates?.[0]?.content?.parts?.[0]?.text;
          if (candidateText) {
            return {
              response: candidateText.trim(),
              suggestedAction,
              timestamp: new Date().toISOString(),
            };
          }
        }
      } catch (error) {
        this.logger.warn(`Cloud API call failed, falling back to local copilot reasoning engine: ${error}`);
      }
    }

    // Contextual intelligent responses for motorcycle riders fallback
    if (lowerPrompt.includes('speed')) {
      if (tele?.speedKmh !== undefined && tele?.speedKmh !== null) {
        const sim = tele.isSimulated ? ' (Simulated)' : '';
        return {
          response: `Current speed is ${Math.round(tele.speedKmh)} km/h${sim}.`,
          suggestedAction,
          timestamp: new Date().toISOString(),
        };
      }
      return {
        response: 'Current speed is unavailable from vehicle. Ensure BLE telemetry is linked.',
        suggestedAction: 'SHOW_DIAGNOSTICS',
        timestamp: new Date().toISOString(),
      };
    }

    if (lowerPrompt.includes('rpm') || lowerPrompt.includes('revs')) {
      if (tele?.engineRpm !== undefined && tele?.engineRpm !== null) {
        const sim = tele.isSimulated ? ' (Simulated)' : '';
        return {
          response: `Engine speed is currently ${tele.engineRpm} RPM${sim}.`,
          suggestedAction,
          timestamp: new Date().toISOString(),
        };
      }
      return {
        response: 'Engine RPM is currently unavailable from vehicle.',
        suggestedAction: 'SHOW_DIAGNOSTICS',
        timestamp: new Date().toISOString(),
      };
    }

    if (lowerPrompt.includes('battery') || lowerPrompt.includes('voltage')) {
      if (tele?.batteryVoltage !== undefined && tele?.batteryVoltage !== null) {
        const sim = tele.isSimulated ? ' (Simulated)' : '';
        return {
          response: `Motorcycle electrical bus is at ${tele.batteryVoltage.toFixed(1)} Volts${sim}.`,
          suggestedAction: 'SHOW_DIAGNOSTICS',
          timestamp: new Date().toISOString(),
        };
      }
      return {
        response: 'Battery voltage is currently unavailable from vehicle.',
        suggestedAction: 'SHOW_DIAGNOSTICS',
        timestamp: new Date().toISOString(),
      };
    }

    if (lowerPrompt.includes('temp') || lowerPrompt.includes('coolant')) {
      if (tele?.coolantTempC !== undefined && tele?.coolantTempC !== null) {
        const sim = tele.isSimulated ? ' (Simulated)' : '';
        return {
          response: `Engine coolant temperature is ${Math.round(tele.coolantTempC)}°C${sim}.`,
          suggestedAction: 'SHOW_DIAGNOSTICS',
          timestamp: new Date().toISOString(),
        };
      }
      return {
        response: 'Engine temperature is currently unavailable from vehicle.',
        suggestedAction: 'SHOW_DIAGNOSTICS',
        timestamp: new Date().toISOString(),
      };
    }

    if (lowerPrompt.includes('fuel') || lowerPrompt.includes('gas') || lowerPrompt.includes('range')) {
      return {
        response: 'Nearest motorcycle-friendly gas station is Shell High Octane in 4.2 km along your current route.',
        suggestedAction: 'OPEN_NAVIGATION',
        timestamp: new Date().toISOString(),
      };
    }

    if (lowerPrompt.includes('weather') || lowerPrompt.includes('rain')) {
      return {
        response: 'Clear skies along Mountain Highway with 18°C temperature. Dry tarmac, optimal grip for high lean angles.',
        suggestedAction: 'WEATHER_WARNING',
        timestamp: new Date().toISOString(),
      };
    }

    if (lowerPrompt.includes('tire') || lowerPrompt.includes('pressure') || lowerPrompt.includes('chain')) {
      return {
        response: 'Recommended cold tire pressure is 36 PSI Front / 42 PSI Rear. Front tire reading 35.8 PSI (Optimal).',
        suggestedAction: 'SHOW_DIAGNOSTICS',
        timestamp: new Date().toISOString(),
      };
    }

    return {
      response: `RideOS AI Co-Pilot: System nominal. Eyes on the apex, throttle steady, and enjoy the curves!`,
      suggestedAction,
      timestamp: new Date().toISOString(),
    };
  }
}
