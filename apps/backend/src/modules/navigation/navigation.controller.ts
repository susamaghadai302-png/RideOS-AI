import { Controller, Post, Get, Body, Query, UseGuards, Req } from '@nestjs/common';
import { NavigationService } from './navigation.service';
import { CalculateRouteDto, GeoPointDto } from './dto/calculate-route.dto';
import { ReportHazardDto } from './dto/report-hazard.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('navigation')
@UseGuards(JwtAuthGuard)
export class NavigationController {
  constructor(private readonly navigationService: NavigationService) {}

  @Post('route')
  async calculateRoute(@Body() dto: CalculateRouteDto) {
    return this.navigationService.calculateRoute(dto);
  }

  @Post('hazards')
  async reportHazard(@Req() req: any, @Body() dto: ReportHazardDto) {
    return this.navigationService.reportHazard(req.user.userId, dto);
  }

  @Get('hazards/nearby')
  async getNearbyHazards(
    @Query('lat') lat: string,
    @Query('lng') lng: string,
    @Query('radius') radius?: string,
  ) {
    const latitude = parseFloat(lat);
    const longitude = parseFloat(lng);
    const rad = radius ? parseInt(radius, 10) : 5000;
    return this.navigationService.findNearbyHazards(latitude, longitude, rad);
  }

  @Post('recalculate-check')
  async checkOffRoute(@Body() body: { currentLocation: GeoPointDto; waypoints: GeoPointDto[] }) {
    return this.navigationService.checkOffRoute(body.currentLocation, body.waypoints);
  }
}
