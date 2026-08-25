import { Controller, Get, Post, Patch, Delete, Param, Body, UseGuards, Req } from '@nestjs/common';
import { VehicleHealthService } from './vehicle_health.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import {
  LogDiagnosticEventDto,
  CreateMaintenanceRecordDto,
  CreateVehicleAlertDto,
  CreateVehicleDocumentDto,
} from './dto/vehicle_health.dto';

@Controller('vehicle-health')
@UseGuards(JwtAuthGuard)
export class VehicleHealthController {
  constructor(private readonly healthService: VehicleHealthService) {}

  // Diagnostics
  @Post('diagnostics')
  async logDiagnosticEvent(@Req() req: any, @Body() dto: LogDiagnosticEventDto) {
    return this.healthService.logDiagnosticEvent(req.user.userId, dto);
  }

  @Patch('diagnostics/:id/resolve')
  async resolveDiagnosticEvent(@Req() req: any, @Param('id') id: string) {
    return this.healthService.resolveDiagnosticEvent(req.user.userId, id);
  }

  @Get('diagnostics/:vehicleId/active')
  async getActiveDiagnostics(@Req() req: any, @Param('vehicleId') vehicleId: string) {
    return this.healthService.getActiveDiagnostics(req.user.userId, vehicleId);
  }

  @Get('diagnostics/:vehicleId/history')
  async getDiagnosticHistory(@Req() req: any, @Param('vehicleId') vehicleId: string) {
    return this.healthService.getDiagnosticHistory(req.user.userId, vehicleId);
  }

  // Maintenance
  @Post('maintenance')
  async createMaintenanceRecord(@Req() req: any, @Body() dto: CreateMaintenanceRecordDto) {
    return this.healthService.createMaintenanceRecord(req.user.userId, dto);
  }

  @Get('maintenance/:vehicleId')
  async getMaintenanceHistory(@Req() req: any, @Param('vehicleId') vehicleId: string) {
    return this.healthService.getMaintenanceHistory(req.user.userId, vehicleId);
  }

  // Alerts
  @Post('alerts')
  async createOrUpdateAlert(@Req() req: any, @Body() dto: CreateVehicleAlertDto) {
    return this.healthService.createOrUpdateAlert(req.user.userId, dto);
  }

  @Patch('alerts/:id/acknowledge')
  async acknowledgeAlert(@Req() req: any, @Param('id') id: string) {
    return this.healthService.acknowledgeAlert(req.user.userId, id);
  }

  @Patch('alerts/:id/resolve')
  async resolveAlert(@Req() req: any, @Param('id') id: string) {
    return this.healthService.resolveAlert(req.user.userId, id);
  }

  @Get('alerts/:vehicleId')
  async getActiveAlerts(@Req() req: any, @Param('vehicleId') vehicleId: string) {
    return this.healthService.getActiveAlerts(req.user.userId, vehicleId);
  }

  // Documents
  @Post('documents')
  async createVehicleDocument(@Req() req: any, @Body() dto: CreateVehicleDocumentDto) {
    return this.healthService.createVehicleDocument(req.user.userId, dto);
  }

  @Get('documents/:vehicleId')
  async getVehicleDocuments(@Req() req: any, @Param('vehicleId') vehicleId: string) {
    return this.healthService.getVehicleDocuments(req.user.userId, vehicleId);
  }

  @Delete('documents/:id')
  async deleteVehicleDocument(@Req() req: any, @Param('id') id: string) {
    return this.healthService.deleteVehicleDocument(req.user.userId, id);
  }

  // Predictive Health Summary
  @Get(':vehicleId/predictive-summary')
  async getPredictiveSummary(@Req() req: any, @Param('vehicleId') vehicleId: string) {
    return this.healthService.getPredictiveHealthSummary(req.user.userId, vehicleId);
  }
}
