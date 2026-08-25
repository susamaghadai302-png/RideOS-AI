import { Controller, Get, Query } from '@nestjs/common';
import { WeatherService } from './weather.service';

@Controller('weather')
export class WeatherController {
  constructor(private readonly weatherService: WeatherService) {}

  @Get('alert')
  async getWeatherAlert(
    @Query('lat') lat: string,
    @Query('lng') lng: string,
  ) {
    const latitude = parseFloat(lat) || 37.7749;
    const longitude = parseFloat(lng) || -122.4194;
    return this.weatherService.getWeatherAlert(latitude, longitude);
  }
}
