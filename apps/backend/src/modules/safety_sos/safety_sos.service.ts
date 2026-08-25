import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { SosIncident, SosIncidentDocument } from './schemas/sos-incident.schema';
import { TriggerSosDto } from './dto/trigger-sos.dto';
import { EmergencyDispatcherService } from './services/emergency-dispatcher.service';
import { RidersService } from '../riders/riders.service';

@Injectable()
export class SafetySosService {
  constructor(
    @InjectModel(SosIncident.name) private readonly sosModel: Model<SosIncidentDocument>,
    private readonly dispatcherService: EmergencyDispatcherService,
    private readonly ridersService: RidersService,
  ) {}

  async triggerSos(riderId: string, dto: TriggerSosDto): Promise<SosIncidentDocument> {
    const incident = new this.sosModel({
      riderId,
      triggerType: dto.triggerType,
      status: 'DISPATCHED',
      location: {
        type: 'Point',
        coordinates: [dto.lng, dto.lat],
      },
      impactForceG: dto.impactForceG,
      tripId: dto.tripId,
      dispatchedAt: new Date(),
    });

    await incident.save();

    // Fetch rider emergency contacts and trigger dispatch
    try {
      const rider = await this.ridersService.findById(riderId);
      if (rider && rider.emergencyContacts) {
        await this.dispatcherService.dispatchEmergencyAlert(
          riderId,
          incident._id.toString(),
          dto.lat,
          dto.lng,
          rider.emergencyContacts,
        );
      }
    } catch (_) {}

    return incident;
  }

  async cancelSos(riderId: string, incidentId: string): Promise<SosIncidentDocument> {
    const incident = await this.sosModel.findOne({ _id: incidentId, riderId });
    if (!incident) {
      throw new NotFoundException('SOS incident not found');
    }
    incident.status = 'CANCELLED';
    return incident.save();
  }

  async getActiveIncidents() {
    return this.sosModel.find({ status: 'DISPATCHED' }).sort({ createdAt: -1 }).exec();
  }
}
