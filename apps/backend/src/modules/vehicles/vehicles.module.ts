import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { VehiclesService } from './vehicles.service';
import { VehiclesController } from './vehicles.controller';
import { UserVehicle, UserVehicleSchema } from './schemas/user-vehicle.schema';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: UserVehicle.name, schema: UserVehicleSchema }]),
  ],
  controllers: [VehiclesController],
  providers: [VehiclesService],
  exports: [VehiclesService],
})
export class VehiclesModule {}
