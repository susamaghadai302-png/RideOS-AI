export interface CreateSquadDto {
  title: string;
  routeId?: string;
}

export interface JoinSquadDto {
  squadCode: string;
}

export interface SquadMemberDto {
  riderId: string;
  fullName: string;
  lat?: number;
  lng?: number;
  speedKmh?: number;
  isCreator: boolean;
  joinedAt: string;
}

export interface SquadRoomDto {
  squadId: string;
  squadCode: string;
  title: string;
  creatorId: string;
  members: SquadMemberDto[];
  isActive: boolean;
  createdAt: string;
}

export interface SquadLocationUpdateDto {
  squadId: string;
  lat: number;
  lng: number;
  speedKmh: number;
  headingDegree?: number;
}
