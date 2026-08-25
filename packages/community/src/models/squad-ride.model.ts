export interface SquadMemberLocation {
  riderId: string;
  riderName: string;
  lat: number;
  lng: number;
  speedKmh: number;
  lastUpdated: string;
}

export interface SquadRide {
  id: string;
  name: string;
  leaderRiderId: string;
  inviteCode: string;
  members: SquadMemberLocation[];
  activeRouteId?: string;
  createdAt: string;
}
