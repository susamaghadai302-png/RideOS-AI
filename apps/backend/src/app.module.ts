import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { validateEnv } from './core/config/env.config';
import { DatabaseModule } from './database/database.module';
import { AuthModule } from './modules/auth/auth.module';
import { RidersModule } from './modules/riders/riders.module';
import { MapsModule } from './modules/maps/maps.module';
import { NavigationModule } from './modules/navigation/navigation.module';
import { TelematicsModule } from './modules/telematics/telematics.module';
import { AiAssistantModule } from './modules/ai_assistant/ai_assistant.module';
import { SafetySosModule } from './modules/safety_sos/safety_sos.module';
import { SquadModule } from './modules/squad/squad.module';
import { ObdDiagnosticsModule } from './modules/obd_diagnostics/obd_diagnostics.module';
import { WeatherModule } from './modules/weather/weather.module';
import { PushNotificationsModule } from './modules/push-notifications/push-notifications.module';
import { CloudSyncModule } from './modules/cloud-sync/cloud-sync.module';
import { MaintenanceModule } from './modules/maintenance/maintenance.module';
import { TripPlannerModule } from './modules/trip_planner/trip_planner.module';
import { DiscoveryModule } from './modules/discovery/discovery.module';
import { RideHistoryModule } from './modules/ride_history/ride_history.module';
import { AnalyticsModule } from './modules/analytics/analytics.module';
import { HealthModule } from './modules/health/health.module';
import { GarageModule } from './modules/garage/garage.module';
import { VehicleRegistryModule } from './modules/vehicle_registry/vehicle_registry.module';
import { TelemetryModule } from './modules/telemetry/telemetry.module';
import { TripsModule } from './modules/trips/trips.module';
import { VehicleHealthModule } from './modules/vehicle_health/vehicle_health.module';
import { DevicesModule } from './modules/devices/devices.module';
import { DigitalTwinModule } from './modules/digital_twin/digital_twin.module';
import { TelemetryGateway } from './websocket/telemetry.gateway';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      validate: validateEnv,
    }),
    ThrottlerModule.forRoot([
      {
        ttl: 60000,
        limit: 100,
      },
    ]),
    DatabaseModule,
    HealthModule,
    AuthModule,
    RidersModule,
    MapsModule,
    NavigationModule,
    TelematicsModule,
    AiAssistantModule,
    SafetySosModule,
    SquadModule,
    ObdDiagnosticsModule,
    WeatherModule,
    PushNotificationsModule,
    CloudSyncModule,
    MaintenanceModule,
    TripPlannerModule,
    DiscoveryModule,
    RideHistoryModule,
    AnalyticsModule,
    GarageModule,
    VehicleRegistryModule,
    TelemetryModule,
    TripsModule,
    VehicleHealthModule,
    DevicesModule,
    DigitalTwinModule,
  ],
  providers: [TelemetryGateway],
})
export class AppModule {}

