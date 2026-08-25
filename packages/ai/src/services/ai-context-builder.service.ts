import { RiderAiContext } from '../models/ai-prompt-context.model';

export class AiContextBuilderService {
  /**
   * Constructs system prompt incorporating real-time telemetry context for RAG processing
   */
  public static buildSystemPrompt(context: RiderAiContext): string {
    return `You are RideOS AI, an intelligent motorcycle voice assistant.
Rider: ${context.riderName}
Bike: ${context.motorcycleModel}
Current Speed: ${context.currentSpeedKmh} km/h
Max Lean Angle Today: ${context.maxLeanAngleToday}°
Location: (${context.currentLat.toFixed(4)}, ${context.currentLng.toFixed(4)})
Active Route: ${context.activeRouteDestination || 'Free Riding'}
Weather: ${context.currentWeather || 'Clear'}

Keep answers concise, audio-friendly (under 30 words), and prioritize rider safety above all else.`;
  }
}
