export class SosPayloadBuilderService {
  /**
   * Generates live tracking URL for emergency contacts
   */
  public static buildLiveTrackingUrl(incidentId: string): string {
    return `https://sos.rideos.ai/track/${incidentId}`;
  }

  /**
   * Builds localized emergency SMS text payload
   */
  public static buildEmergencySmsMessage(
    riderName: string,
    lat: number,
    lng: number,
    incidentId: string,
  ): string {
    const trackingUrl = this.buildLiveTrackingUrl(incidentId);
    return `EMERGENCY ALERT: ${riderName} has been involved in a motorcycle incident. Location: https://maps.google.com/?q=${lat},${lng}. Live telemetry: ${trackingUrl}`;
  }
}
