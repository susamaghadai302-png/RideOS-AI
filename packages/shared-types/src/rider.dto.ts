export interface EmergencyContactDto {
  name: string;
  phone: string;
  relation: string;
}

export interface MotorcycleDto {
  bikeId: string;
  make: string;
  model: string;
  year: number;
  engineCC: number;
  maxLeanAngleLimit?: number;
  isPrimary: boolean;
}

export interface RiderPreferencesDto {
  routingPreference: 'SCENIC_TWISTY' | 'FASTEST' | 'AVOID_HIGHWAYS';
  voiceAlertsEnabled: boolean;
  sosAutoDispatchDelaySeconds: number;
  units: 'METRIC' | 'IMPERIAL';
}

export interface RiderProfileDto {
  id: string;
  email: string;
  fullName: string;
  phone: string;
  emergencyContacts: EmergencyContactDto[];
  garage: MotorcycleDto[];
  preferences: RiderPreferencesDto;
  createdAt: string;
}
