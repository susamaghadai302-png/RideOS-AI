import { Injectable, Logger } from '@nestjs/common';

@Injectable()
export class EmergencyDispatcherService {
  private readonly logger = new Logger(EmergencyDispatcherService.name);

  async dispatchEmergencyAlert(
    riderId: string,
    incidentId: string,
    lat: number | undefined,
    lng: number | undefined,
    emergencyContacts: any[],
  ) {
    const liveTrackingUrl = `https://rideos.ai/track/sos/${incidentId}`;
    this.logger.warn(
      `🚨 EMERGENCY DISPATCH ACTIVATED FOR RIDER ${riderId}! Live Tracking: ${liveTrackingUrl}`,
    );

    for (const contact of emergencyContacts) {
      const locString = (lat != null && lng != null) ? `Live GPS position: ${liveTrackingUrl}` : `Location unavailable.`;
      this.logger.log(
        `Sending Emergency SMS to ${contact.name} (${contact.phone}): "CRASH ALERT: Rider may be in an accident! ${locString}"`,
      );
    }

    return { dispatchedContactsCount: emergencyContacts.length, liveTrackingUrl };
  }
}
