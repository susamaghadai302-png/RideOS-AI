import { Controller, Post, Get, Body, Param, UseGuards, Req } from '@nestjs/common';
import { TelematicsService } from './telematics.service';
import { StreamTelemetryDto } from './dto/stream-telemetry.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('telematics')
@UseGuards(JwtAuthGuard)
export class TelematicsController {
  constructor(private readonly telematicsService: TelematicsService) {}

  @Post('stream')
  async ingestTelemetry(@Req() req: any, @Body() dto: StreamTelemetryDto) {
    return this.telematicsService.processTelemetry(req.user.userId, dto);
  }

  @Get('trip/:tripId/summary')
  async getTripSummary(@Param('tripId') tripId: string) {
    return this.telematicsService.getTripSummary(tripId);
  }
}
