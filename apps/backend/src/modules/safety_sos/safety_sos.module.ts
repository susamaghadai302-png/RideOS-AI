import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { SosIncident, SosIncidentSchema } from './schemas/sos-incident.schema';
import { SafetySosController } from './safety_sos.controller';
import { SafetySosService } from './safety_sos.service';
import { EmergencyDispatcherService } from './services/emergency-dispatcher.service';
import { RidersModule } from '../riders/riders.module';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: SosIncident.name, schema: SosIncidentSchema }]),
    RidersModule,
  ],
  controllers: [SafetySosController],
  providers: [SafetySosService, EmergencyDispatcherService],
  exports: [SafetySosService],
})
export class SafetySosModule {}
