export type RoadCondition = 'DRY' | 'WET' | 'SLIPPERY' | 'ICY';

export interface MotorcycleWeatherAlert {
  lat: number;
  lng: number;
  tempCelsius: number;
  rainProbabilityPercent: number;
  windSpeedKmh: number;
  windGustKmh: number;
  roadCondition: RoadCondition;
  warningMessage?: string;
  isHighWindRisk: boolean;
  isRainRisk: boolean;
}
