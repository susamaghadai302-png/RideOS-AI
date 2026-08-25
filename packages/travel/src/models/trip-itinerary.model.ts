export type StopType = 'WAYPOINT' | 'FUEL_STOP' | 'SCENIC_REST' | 'OVERNIGHT_HOTEL';

export interface WaypointStop {
  title: string;
  type: StopType;
  lat: number;
  lng: number;
  estimatedDurationMinutes?: number;
}

export interface DayItinerary {
  dayNumber: number;
  distanceKm: number;
  estimatedRidingTimeHours: number;
  stops: WaypointStop[];
}

export interface TripPlan {
  id: string;
  title: string;
  totalDistanceKm: number;
  totalDays: number;
  days: DayItinerary[];
}
