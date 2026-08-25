export type ManeuverType =
  | 'DEPART'
  | 'TURN_LEFT'
  | 'TURN_RIGHT'
  | 'SHARP_LEFT'
  | 'SHARP_RIGHT'
  | 'SLIGHT_LEFT'
  | 'SLIGHT_RIGHT'
  | 'CONTINUE'
  | 'ROUNDABOUT'
  | 'ARRIVE';

export interface TurnInstruction {
  maneuver: ManeuverType;
  text: string;
  distanceMeters: number;
  streetName: string;
  lat: number;
  lng: number;
}

export interface MotorcycleRoute {
  id: string;
  distanceKm: number;
  durationMinutes: number;
  twistyScore: number; // 0-100 rating for how scenic/curvy the road is
  geometry: Array<[number, number]>; // Array of [lat, lng]
  instructions: TurnInstruction[];
}
