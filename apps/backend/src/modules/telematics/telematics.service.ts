import { Injectable, Inject, Optional } from '@nestjs/common';
import { Pool } from 'pg';
import { TIMESCALE_POOL } from '../../database/timescale.provider';
import { TelemetryBatchWriterService } from './services/telemetry-batch-writer.service';
import { LeanAngleCalculatorService } from './services/lean-angle-calculator.service';
import { StreamTelemetryDto } from './dto/stream-telemetry.dto';

@Injectable()
export class TelematicsService {
  constructor(
    @Optional() @Inject(TIMESCALE_POOL) private readonly timescalePool?: Pool,
    private readonly batchWriter?: TelemetryBatchWriterService,
    private readonly leanAngleCalculator?: LeanAngleCalculatorService,
  ) {}

  processTelemetry(riderId: string, dto: StreamTelemetryDto) {
    if (this.batchWriter) {
      this.batchWriter.enqueueTelemetry(dto, riderId);
    }
    return { status: 'QUEUED', timestamp: new Date().toISOString() };
  }

  async getTripSummary(tripId: string) {
    if (!this.timescalePool) {
      return {
        total_points: '0',
        avg_speed: 0,
        max_speed: 0,
        max_lean_angle: 0,
        max_accel_g: 0,
      };
    }
    const query = `
      SELECT 
        COUNT(*) as total_points,
        AVG(speed_kmh) as avg_speed,
        MAX(speed_kmh) as max_speed,
        MAX(lean_angle) as max_lean_angle,
        MAX(accel_g) as max_accel_g
      FROM telemetry_logs
      WHERE trip_id = $1
    `;
    const res = await this.timescalePool.query(query, [tripId]);
    return res.rows[0] || {};
  }
}
