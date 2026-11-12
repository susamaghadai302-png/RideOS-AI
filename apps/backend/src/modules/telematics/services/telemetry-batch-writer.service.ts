import { Injectable, Inject, Optional, OnModuleDestroy } from '@nestjs/common';
import { Pool } from 'pg';
import { TIMESCALE_POOL } from '../../../database/timescale.provider';
import { StreamTelemetryDto } from '../dto/stream-telemetry.dto';

@Injectable()
export class TelemetryBatchWriterService implements OnModuleDestroy {
  private buffer: { dto: StreamTelemetryDto; riderId: string }[] = [];
  private readonly BATCH_SIZE = 50;
  private readonly FLUSH_INTERVAL_MS = 2000;
  private flushTimer?: NodeJS.Timeout;

  constructor(@Optional() @Inject(TIMESCALE_POOL) private readonly timescalePool?: Pool) {
    if (this.timescalePool) {
      this.flushTimer = setInterval(() => this.flushBuffer(), this.FLUSH_INTERVAL_MS);
    }
  }

  onModuleDestroy() {
    if (this.flushTimer) {
      clearInterval(this.flushTimer);
    }
    this.flushBuffer();
  }

  enqueueTelemetry(dto: StreamTelemetryDto, riderId: string) {
    if (!this.timescalePool) return;
    this.buffer.push({ dto, riderId });
    if (this.buffer.length >= this.BATCH_SIZE) {
      this.flushBuffer();
    }
  }

  async flushBuffer() {
    if (!this.timescalePool || this.buffer.length === 0) return;

    const itemsToFlush = [...this.buffer];
    this.buffer = [];

    try {
      const client = await this.timescalePool.connect();
      const query = `
        INSERT INTO telemetry_logs (
          timestamp, trip_id, rider_id, location, speed_kmh, lean_angle, accel_g, elevation_m, battery_level
        ) VALUES (
          $1, $2, $3, ST_SetSRID(ST_MakePoint($4, $5), 4326), $6, $7, $8, $9, $10
        )
      `;

      for (const item of itemsToFlush) {
        const { dto, riderId } = item;
        await client.query(query, [
          dto.timestamp,
          dto.tripId,
          riderId,
          dto.lng,
          dto.lat,
          dto.speedKmh,
          dto.leanAngle,
          dto.accelG,
          dto.elevationM || 0.0,
          dto.batteryLevel || 100,
        ]);
      }

      client.release();
    } catch (err) {
      console.error('[TelemetryBatchWriter] Flush failed:', err);
    }
  }
}
