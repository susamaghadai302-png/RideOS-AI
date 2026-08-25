export type NotificationCategory =
  | 'EMERGENCY_SOS'
  | 'CRASH_DETECTED'
  | 'THEFT_GEOFENCE'
  | 'TPMS_WARNING'
  | 'HAZARD_ALERT'
  | 'SQUAD_INVITE'
  | 'MAINTENANCE_DUE'
  | 'WEATHER_WARNING';

export interface NotificationPayload {
  id: string;
  recipientRiderId: string;
  category: NotificationCategory;
  title: string;
  body: string;
  deepLinkUrl?: string;
  sentAt: string;
}
