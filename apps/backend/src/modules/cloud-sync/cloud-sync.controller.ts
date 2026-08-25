import { Controller, Post, Get, Body, Param, Req, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { CloudSyncService, BatchSyncPayload } from './cloud-sync.service';
import { SyncRideSessionPayloadDto } from './dto/sync-ride-payload.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@ApiTags('Cloud Synchronization & Fleet Bridge')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('cloud-sync')
export class CloudSyncController {
  constructor(private readonly syncService: CloudSyncService) {}

  @Post('batch')
  @ApiOperation({ summary: 'Batch synchronize offline telemetry points and maintenance events' })
  async syncBatch(@Body() payload: BatchSyncPayload) {
    return this.syncService.processSync(payload);
  }

  @Post('rides')
  @ApiOperation({ summary: 'Upload completed on-road ride session with cryptographic idempotency' })
  async syncRideSession(@Body() dto: SyncRideSessionPayloadDto) {
    return this.syncService.syncRideSession(dto);
  }

  @Get('status')
  @ApiOperation({ summary: 'Get current rider cloud sync status and last upload timestamp' })
  async getStatus(@Req() req: any) {
    const riderId = req.user?.userId || 'rider_default';
    return this.syncService.getSyncStatus(riderId);
  }

  @Get('rides/:riderId')
  @ApiOperation({ summary: 'List historical synced ride sessions for a rider' })
  async listRides(@Param('riderId') riderId: string) {
    return this.syncService.listSyncedSessions(riderId);
  }
}
