import { Controller, Get, Post, Body, Param, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { DevicesService } from './devices.service';
import { ConnectDeviceDto } from './dto/connect-device.dto';
import { StartTelemetrySessionDto, StopTelemetrySessionDto } from './dto/telemetry-session.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@ApiTags('Motorcycle Bluetooth & Fleet Diagnostic Telematics')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller()
export class DevicesController {
  constructor(private readonly devicesService: DevicesService) {}

  @Get('devices')
  @ApiOperation({ summary: 'List all registered and discovered motorcycle hardware devices' })
  async listDevices() {
    return this.devicesService.listDevices();
  }

  @Post('devices/connect')
  @ApiOperation({ summary: 'Initiate telemetry session connection with target motorcycle device' })
  async connectDevice(@Req() req: any, @Body() dto: ConnectDeviceDto) {
    return this.devicesService.connectDevice(req.user?.userId || 'rider_default', dto);
  }

  @Post('devices/disconnect')
  @ApiOperation({ summary: 'Gracefully disconnect hardware link' })
  async disconnectDevice(@Body('deviceId') deviceId: string) {
    return this.devicesService.disconnectDevice(deviceId);
  }

  @Get('devices/:id/status')
  @ApiOperation({ summary: 'Fetch live connection state, RSSI, and battery level of device' })
  async getStatus(@Param('id') id: string) {
    return this.devicesService.getDeviceStatus(id);
  }

  @Get('devices/:id/capabilities')
  @ApiOperation({ summary: 'Query supported sensor and DTC clearance capabilities of device' })
  async getCapabilities(@Param('id') id: string) {
    return this.devicesService.getDeviceCapabilities(id);
  }

  @Get('devices/:id/telemetry')
  @ApiOperation({ summary: 'Get latest normalized telemetry snapshot (RPM, Speed, Temp, Battery)' })
  async getTelemetry(@Param('id') id: string) {
    return this.devicesService.getLatestTelemetry(id);
  }

  @Get('devices/:id/diagnostics')
  @ApiOperation({ summary: 'Get active DTC trouble codes and ECU health status' })
  async getDiagnostics(@Param('id') id: string) {
    return this.devicesService.getDeviceDiagnostics(id);
  }

  @Post('devices/:id/diagnostics/clear')
  @ApiOperation({ summary: 'Clear active DTC trouble codes (only permitted on supported protocols)' })
  async clearDiagnostics(@Param('id') id: string) {
    return this.devicesService.clearDtcCodes(id);
  }

  @Post('telemetry/sessions')
  @ApiOperation({ summary: 'Start a new on-road ride telemetry recording session' })
  async startSession(@Req() req: any, @Body() dto: StartTelemetrySessionDto) {
    return this.devicesService.startSession(req.user?.userId || 'rider_default', dto);
  }

  @Get('telemetry/sessions')
  @ApiOperation({ summary: 'List historical recorded telemetry sessions' })
  async listSessions(@Req() req: any) {
    return this.devicesService.listSessions(req.user?.userId || 'rider_default');
  }

  @Get('telemetry/sessions/:id')
  @ApiOperation({ summary: 'Get details of a specific telemetry session' })
  async getSession(@Param('id') id: string) {
    return this.devicesService.getSession(id);
  }

  @Post('telemetry/sessions/:id/stop')
  @ApiOperation({ summary: 'Stop telemetry session recording and generate ride summary' })
  async stopSession(@Param('id') id: string, @Body() dto: StopTelemetrySessionDto) {
    return this.devicesService.stopSession(id, dto);
  }
}
