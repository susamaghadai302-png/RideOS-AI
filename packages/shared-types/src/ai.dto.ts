export interface AiQueryRequestDto {
  prompt: string;
  riderContext?: {
    currentLat?: number;
    currentLng?: number;
    speedKmh?: number;
    bikeMake?: string;
    bikeModel?: string;
  };
}

export interface AiQueryResponseDto {
  response: string;
  suggestedAction?: 'NAVIGATE_FUEL' | 'WEATHER_WARNING' | 'MAINTENANCE_TIP';
  timestamp: string;
}
