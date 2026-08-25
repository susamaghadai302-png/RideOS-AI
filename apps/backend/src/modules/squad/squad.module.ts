import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { SquadController } from './squad.controller';
import { SquadService } from './squad.service';
import { SquadRoom, SquadRoomSchema } from './schemas/squad-room.schema';
import { RidersModule } from '../riders/riders.module';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: SquadRoom.name, schema: SquadRoomSchema }]),
    RidersModule,
  ],
  controllers: [SquadController],
  providers: [SquadService],
  exports: [SquadService],
})
export class SquadModule {}
