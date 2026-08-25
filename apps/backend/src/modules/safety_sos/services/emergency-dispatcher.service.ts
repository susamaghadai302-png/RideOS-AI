import { Injectable, Logger } from '@nestjs/common';

@Injectable()
export class EmergencyDispatcherService {
  private readonly logger = new Logger(EmergencyDispatcherService.name);

  async dispatchEmergencyAlert(
    riderId: string,
    incidentId: string,
    lat: number,
    lng: number,
    emergencyContacts: any[],
  ) {
    const liveTrackingUrl = `https://rideos.ai/track/sos/${incidentId}`;
    this.logger.warn(
      `🚨 EMERGENCY DISPATCH ACTIVATED FOR RIDER ${riderId}! Live Tracking: ${liveTrackingUrl}`,
    );

    for (const contact of emergencyContacts) {
      this.logger.log(
        `Sending Emergency SMS to ${contact.name} (${contact.phone}): "CRASH ALERT: Rider may be in an accident! Live GPS position: ${liveTrackingUrl}"`,
      );
    }

    return { dispatchedContactsCount: emergencyContacts.length, liveTrackingUrl };
  }
}
