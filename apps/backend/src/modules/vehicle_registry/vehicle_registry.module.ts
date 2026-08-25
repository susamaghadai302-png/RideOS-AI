import { Module, OnModuleInit } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { VehicleModel, VehicleModelSchema } from './schemas/vehicle_model.schema';
import { VehicleRegistryController } from './vehicle_registry.controller';
import { VehicleRegistryService } from './vehicle_registry.service';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: VehicleModel.name, schema: VehicleModelSchema }]),
  ],
  controllers: [VehicleRegistryController],
  providers: [VehicleRegistryService],
  exports: [VehicleRegistryService]
})
export class VehicleRegistryModule implements OnModuleInit {
  constructor(private readonly registryService: VehicleRegistryService) {}

  async onModuleInit() {
    await this.registryService.seedDemoRegistry();
  }
}
