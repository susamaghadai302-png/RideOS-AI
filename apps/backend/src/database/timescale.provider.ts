import { Provider } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Pool } from 'pg';

export const TIMESCALE_POOL = 'TIMESCALE_POOL';

export const TimescaleProvider: Provider = {
  provide: TIMESCALE_POOL,
  useFactory: async (configService: ConfigService) => {
    const pool = new Pool({
      host: configService.get<string>('TIMESCALE_HOST', 'localhost'),
      port: configService.get<number>('TIMESCALE_PORT', 5432),
      user: configService.get<string>('TIMESCALE_USER', 'rideos_admin'),
      password: configService.get<string>('TIMESCALE_PASSWORD', 'rideos_secure_password'),
      database: configService.get<string>('TIMESCALE_DB', 'rideos_telemetry'),
      max: 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 1000,
    });

    pool.on('error', (err) => {
      console.warn('[TimescaleDB] Pool error warning:', err.message);
    });

    try {
      const client = await pool.connect();
      console.log('[TimescaleDB] Connection pool established successfully');
      await client.query(`
        CREATE TABLE IF NOT EXISTS telemetry_logs (
          timestamp       TIMESTAMPTZ NOT NULL,
          trip_id         UUID NOT NULL,
          rider_id        VARCHAR(64) NOT NULL,
          location        GEOMETRY(Point, 4326),
          speed_kmh       REAL NOT NULL,
          lean_angle      REAL NOT NULL,
          accel_g         REAL NOT NULL,
          elevation_m     REAL NOT NULL,
          battery_level   SMALLINT NOT NULL
        );
      `);
      client.release();
    } catch (err: any) {
      console.warn('[TimescaleDB] Connection warning (running without TimescaleDB):', err.message);
    }

    return pool;
  },
  inject: [ConfigService],
};
