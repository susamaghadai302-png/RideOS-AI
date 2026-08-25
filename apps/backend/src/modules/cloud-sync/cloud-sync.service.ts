import { Injectable, Logger, ConflictException } from '@nestjs/common';
import { SyncRideSessionPayloadDto } from './dto/sync-ride-payload.dto';

export interface BatchSyncPayload {
  riderId: string;
  telemetryBatch: Array<{ timestamp: string; lat: number; lng: number; speedKmh: number }>;
  pendingMaintenanceLogs: Array<{ taskType: string; performedAtKm: number }>;
}

@Injectable()
export class CloudSyncService {
  private readonly logger = new Logger(CloudSyncService.name);
  private readonly syncedSessions = new Map<string, SyncRideSessionPayloadDto>();

  async processSync(payload: BatchSyncPayload) {
    this.logger.log(
      `[CloudSync] Syncing ${payload.telemetryBatch.length} telemetry points & ${payload.pendingMaintenanceLogs.length} logs for rider ${payload.riderId}`,
    );

    return {
      status: 'SYNCED',
      syncedPointsCount: payload.telemetryBatch.length,
      syncedLogsCount: payload.pendingMaintenanceLogs.length,
      serverTimestamp: new Date().toISOString(),
    };
  }

  async syncRideSession(dto: SyncRideSessionPayloadDto) {
    if (this.syncedSessions.has(dto.sessionId)) {
      this.logger.warn(`[CloudSync] Duplicate session sync detected for ${dto.sessionId}. Returning idempotent success.`);
      return {
        status: 'SYNCED',
        isDuplicate: true,
        sessionId: dto.sessionId,
        syncedAt: new Date().toISOString(),
      };
    }

    this.syncedSessions.set(dto.sessionId, dto);
    this.logger.log(`[CloudSync] Successfully synced ride session ${dto.sessionId} for rider ${dto.riderId}`);

    return {
      status: 'SYNCED',
      isDuplicate: false,
      sessionId: dto.sessionId,
      syncedAt: new Date().toISOString(),
    };
  }

  async getSyncStatus(riderId: string) {
    const userSessions = Array.from(this.syncedSessions.values()).filter((s) => s.riderId === riderId);
    return {
      riderId,
      totalSyncedSessions: userSessions.length,
      lastSyncTimestamp: userSessions.length > 0 ? userSessions[userSessions.length - 1].endTime : null,
      serverStatus: 'ONLINE',
    };
  }

  async listSyncedSessions(riderId: string): Promise<SyncRideSessionPayloadDto[]> {
    return Array.from(this.syncedSessions.values()).filter((s) => s.riderId === riderId || riderId === 'all');
  }
}
