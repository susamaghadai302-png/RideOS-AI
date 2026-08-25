import { Controller, Get, Query } from '@nestjs/common';
import { MapsService } from './maps.service';

@Controller('maps')
export class MapsController {
  constructor(private readonly mapsService: MapsService) {}

  @Get('pois')
  async getPois(
    @Query('lat') lat: string,
    @Query('lng') lng: string,
    @Query('radius') radius?: string,
  ) {
    const latitude = parseFloat(lat) || 37.7749;
    const longitude = parseFloat(lng) || -122.4194;
    const rad = radius ? parseFloat(radius) : 10;
    return this.mapsService.getNearbyPois(latitude, longitude, rad);
  }

  @Get('search')
  async searchPlaces(@Query('q') query: string) {
    return this.mapsService.searchPlaces(query || '');
  }

  @Get('client-key')
  getClientKey() {
    return { apiKey: process.env.GOOGLE_MAPS_API_KEY || '' };
  }
}
