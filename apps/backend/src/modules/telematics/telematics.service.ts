import { Injectable, Inject } from '@nestjs/common';
import { Pool } from 'pg';
import { TIMESCALE_POOL } from '../../database/timescale.provider';
import { TelemetryBatchWriterService } from './services/telemetry-batch-writer.service';
import { LeanAngleCalculatorService } from './services/lean-angle-calculator.service';
import { StreamTelemetryDto } from './dto/stream-telemetry.dto';

@Injectable()
export class TelematicsService {
  constructor(
    @Inject(TIMESCALE_POOL) private readonly timescalePool: Pool,
    private readonly batchWriter: TelemetryBatchWriterService,
    private readonly leanAngleCalculator: LeanAngleCalculatorService,
  ) {}

  processTelemetry(riderId: string, dto: StreamTelemetryDto) {
    this.batchWriter.enqueueTelemetry(dto, riderId);
    return { status: 'QUEUED', timestamp: new Date().toISOString() };
  }

  async getTripSummary(tripId: string) {
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
