import { Controller, Get, Param, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AnalyticsService } from './analytics.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@ApiTags('Fleet Analytics & Rider Intelligence')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('analytics')
export class AnalyticsController {
  constructor(private readonly analyticsService: AnalyticsService) {}

  @Get('score/:riderId')
  @ApiOperation({ summary: 'Get single rider performance and safety score' })
  async getScore(@Param('riderId') riderId: string) {
    return this.analyticsService.getRiderScore(riderId);
  }

  @Get('fleet')
  @ApiOperation({ summary: 'Get aggregated fleet metrics, distance trends, and recent ride timeline' })
  async getFleetSummary(@Req() req: any) {
    const riderId = req.user?.userId || 'rider_default';
    return this.analyticsService.getFleetSummary(riderId);
  }
}
