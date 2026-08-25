export interface SosTriggerDto {
  riderId: string;
  tripId?: string;
  lat: number;
  lng: number;
  impactForceG?: number;
  triggerType: 'MANUAL' | 'AUTOMATIC_IMPACT' | 'FALL_DETECTION';
  timestamp: string;
}

export interface SosIncidentDto {
  incidentId: string;
  riderId: string;
  status: 'PENDING_COUNTDOWN' | 'DISPATCHED' | 'CANCELLED' | 'RESOLVED';
  location: { lat: number; lng: number };
  triggeredAt: string;
  dispatchedAt?: string;
}
