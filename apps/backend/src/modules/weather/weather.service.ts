import { Injectable } from '@nestjs/common';
import { MotorcycleWeatherAlert } from '@rideos/shared';

@Injectable()
export class WeatherService {
  async getWeatherAlert(lat: number, lng: number): Promise<MotorcycleWeatherAlert> {
    return {
      lat,
      lng,
      tempCelsius: 18.5,
      rainProbabilityPercent: 15,
      windSpeedKmh: 22.0,
      windGustKmh: 35.0,
      roadCondition: 'DRY',
      warningMessage: 'Moderate crosswinds on Mountain Pass bridges. Exercise caution.',
      isHighWindRisk: true,
      isRainRisk: false,
    };
  }
}
