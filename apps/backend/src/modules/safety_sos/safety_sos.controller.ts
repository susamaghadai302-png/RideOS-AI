import { Controller, Post, Get, Body, Param, UseGuards, Req } from '@nestjs/common';
import { SafetySosService } from './safety_sos.service';
import { TriggerSosDto } from './dto/trigger-sos.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('sos')
@UseGuards(JwtAuthGuard)
export class SafetySosController {
  constructor(private readonly sosService: SafetySosService) {}

  @Post('trigger')
  async triggerSos(@Req() req: any, @Body() dto: TriggerSosDto) {
    return this.sosService.triggerSos(req.user.userId, dto);
  }

  @Post('cancel/:incidentId')
  async cancelSos(@Req() req: any, @Param('incidentId') incidentId: string) {
    return this.sosService.cancelSos(req.user.userId, incidentId);
  }

  @Get('incidents/active')
  async getActiveIncidents() {
    return this.sosService.getActiveIncidents();
  }
}
