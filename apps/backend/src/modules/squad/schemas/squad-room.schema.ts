import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type SquadRoomDocument = SquadRoom & Document;

@Schema()
export class SquadMember {
  @Prop({ required: true })
  riderId: string;

  @Prop({ required: true })
  fullName: string;

  @Prop()
  lat?: number;

  @Prop()
  lng?: number;

  @Prop()
  speedKmh?: number;

  @Prop({ default: false })
  isCreator: boolean;

  @Prop({ default: Date.now })
  joinedAt: Date;
}

const SquadMemberSchema = SchemaFactory.createForClass(SquadMember);

@Schema({ timestamps: true })
export class SquadRoom {
  @Prop({ required: true, unique: true, index: true })
  squadCode: string;

  @Prop({ required: true })
  title: string;

  @Prop({ required: true })
  creatorId: string;

  @Prop({ type: [SquadMemberSchema], default: [] })
  members: SquadMember[];

  @Prop()
  routeId?: string;

  @Prop({ default: true })
  isActive: boolean;
}

export const SquadRoomSchema = SchemaFactory.createForClass(SquadRoom);
