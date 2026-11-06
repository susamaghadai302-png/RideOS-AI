export type SupportedLanguage = 'en' | 'hi' | 'hinglish' | 'or';

export interface RiderMemoryItem {
  key: string;
  value: string;
  category?: string;
}

export interface RiderAiContext {
  riderId: string;
  riderName: string;
  motorcycleModel: string;
  currentSpeedKmh: number;
  maxLeanAngleToday: number;
  currentLat: number;
  currentLng: number;
  currentWeather?: string;
  activeRouteDestination?: string;
  language?: SupportedLanguage;
  memories?: RiderMemoryItem[];
  preferredUnits?: 'metric' | 'imperial';
}
