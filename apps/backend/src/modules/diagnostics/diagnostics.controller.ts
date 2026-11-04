import { Controller, Post, Get, Body, Param, UseGuards, Request, HttpCode, HttpStatus } from '@nestjs/common';
import { DiagnosticsService } from './diagnostics.service';
import { SubmitDiagnosticScanDto } from './dto/diagnostic-scan.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('vehicles/:vehicleId/diagnostics')
@UseGuards(JwtAuthGuard)
export class DiagnosticsController {
  constructor(private readonly diagnosticsService: DiagnosticsService) {}

  @Post('scans')
  async submitScan(
    @Request() req,
    @Param('vehicleId') vehicleId: string,
    @Body() submitScanDto: SubmitDiagnosticScanDto,
  ) {
    const userId = (req.user as any)?.userId || (req.user as any)?.sub;
    return this.diagnosticsService.submitScan(userId, vehicleId, submitScanDto);
  }

  @Get('scans')
  async getScans(
    @Request() req,
    @Param('vehicleId') vehicleId: string,
  ) {
    const userId = (req.user as any)?.userId || (req.user as any)?.sub;
    return this.diagnosticsService.getScansForVehicle(userId, vehicleId);
  }

  @Post('dtcs/clear')
  @HttpCode(HttpStatus.OK)
  async clearDtcs(
    @Request() req,
    @Param('vehicleId') vehicleId: string,
    @Body() body: { transportType: string; protocol: string; speedPayload: string; clearAckPayload: string },
  ) {
    const userId = (req.user as any)?.userId || (req.user as any)?.sub;
    return this.diagnosticsService.clearDtcs(userId, vehicleId, body.transportType, body.protocol, body.speedPayload, body.clearAckPayload);
  }
}
