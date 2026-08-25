import { Controller, Post, Get, Body, Param, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { ObdDiagnosticsService } from './obd_diagnostics.service';
import { StreamObdDataDto } from './dto/obd-data.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@ApiTags('OBD-II Telematics & TPMS Diagnostics')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('obd')
export class ObdDiagnosticsController {
  constructor(private readonly obdService: ObdDiagnosticsService) {}

  @Post('telemetry')
  @ApiOperation({ summary: 'Stream BLE OBD-II sensor values & TPMS tire pressure data' })
  async streamObdData(@Request() req: any, @Body() dto: StreamObdDataDto) {
    return this.obdService.processObdData(req.user.userId, dto);
  }

  @Get('diagnostics/:riderId')
  @ApiOperation({ summary: 'Fetch latest DTC fault codes and TPMS tire pressure report' })
  async getDiagnostics(@Param('riderId') riderId: string) {
    return this.obdService.getLatestDiagnostics(riderId);
  }
}
