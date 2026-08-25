import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { SquadRoom, SquadRoomDocument } from './schemas/squad-room.schema';
import { CreateSquadDto } from './dto/create-squad.dto';
import { JoinSquadDto } from './dto/join-squad.dto';
import { RidersService } from '../riders/riders.service';

@Injectable()
export class SquadService {
  constructor(
    @InjectModel(SquadRoom.name) private readonly squadModel: Model<SquadRoomDocument>,
    private readonly ridersService: RidersService,
  ) {}

  async createSquad(creatorId: string, dto: CreateSquadDto): Promise<SquadRoomDocument> {
    const rider = await this.ridersService.findById(creatorId);
    const squadCode = this.generateSquadCode();

    const newSquad = new this.squadModel({
      squadCode,
      title: dto.title,
      creatorId,
      routeId: dto.routeId,
      members: [
        {
          riderId: creatorId,
          fullName: rider ? rider.fullName : 'Squad Leader',
          isCreator: true,
          joinedAt: new Date(),
        },
      ],
    });

    return newSquad.save();
  }

  async joinSquad(riderId: string, dto: JoinSquadDto): Promise<SquadRoomDocument> {
    const squad = await this.squadModel.findOne({
      squadCode: dto.squadCode.toUpperCase(),
      isActive: true,
    });

    if (!squad) {
      throw new NotFoundException(`Squad room with code "${dto.squadCode}" not found or inactive`);
    }

    const rider = await this.ridersService.findById(riderId);
    const existingMember = squad.members.find((m) => m.riderId === riderId);

    if (!existingMember) {
      squad.members.push({
        riderId,
        fullName: rider ? rider.fullName : 'Rider',
        isCreator: false,
        joinedAt: new Date(),
      } as any);
      await squad.save();
    }

    return squad;
  }

  async getSquadById(squadId: string): Promise<SquadRoomDocument> {
    const squad = await this.squadModel.findById(squadId);
    if (!squad) {
      throw new NotFoundException(`Squad with ID ${squadId} not found`);
    }
    return squad;
  }

  async updateMemberLocation(squadId: string, riderId: string, lat: number, lng: number, speedKmh: number) {
    const squad = await this.squadModel.findById(squadId);
    if (squad) {
      const member = squad.members.find((m) => m.riderId === riderId);
      if (member) {
        member.lat = lat;
        member.lng = lng;
        member.speedKmh = speedKmh;
        await squad.save();
      }
    }
    return squad;
  }

  private generateSquadCode(): string {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    let code = '';
    for (let i = 0; i < 6; i++) {
      code += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return code;
  }
}
