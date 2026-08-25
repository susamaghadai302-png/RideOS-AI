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
}
