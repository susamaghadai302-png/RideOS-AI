import { RiderAiContext } from '../models/ai-prompt-context.model';

export class AiContextBuilderService {
  /**
   * Constructs system prompt incorporating real-time telemetry context, user memories, and language for RAG processing
   */
  public static buildSystemPrompt(context: RiderAiContext): string {
    let languageInstruction = 'Respond concisely in English.';
    if (context.language === 'hi') {
      languageInstruction = 'Respond in concise, rider-friendly Hindi (Devanagari script or clean audio-friendly Hindi).';
    } else if (context.language === 'hinglish') {
      languageInstruction = 'Respond in conversational Hinglish (Hindi words in English alphabet, e.g. "Agla petrol pump 3 km door hai").';
    } else if (context.language === 'or') {
      languageInstruction = 'Respond in concise, natural Odia (ଓଡ଼ିଆ).';
    }

    const memorySnippet = context.memories && context.memories.length > 0
      ? `\nRider Profile & Verified Memories:\n${context.memories.map(m => `- ${m.key}: ${m.value}`).join('\n')}`
      : '';

    return `You are RideOS AI, an intelligent motorcycle voice assistant and digital co-pilot.
Rider: ${context.riderName}
Bike: ${context.motorcycleModel}
Current Speed: ${context.currentSpeedKmh} km/h
Max Lean Angle Today: ${context.maxLeanAngleToday}°
Location: (${context.currentLat.toFixed(4)}, ${context.currentLng.toFixed(4)})
Active Route: ${context.activeRouteDestination || 'Free Riding'}
Weather: ${context.currentWeather || 'Clear'}${memorySnippet}

Language Requirement: ${languageInstruction}
Keep answers concise, audio-friendly (under 30 words), and prioritize rider safety above all else. Never advise actions while leaning or at high speeds.`;
  }
}
