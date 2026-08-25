import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { GarageVehicle, GarageVehicleDocument } from './schemas/garage-vehicle.schema';
import { AddVehicleDto, UpdateConfigurationDto, SetPrimaryVehicleDto } from './dto/garage.dto';

@Injectable()
export class GarageService {
  constructor(
    @InjectModel(GarageVehicle.name) private garageModel: Model<GarageVehicleDocument>,
  ) {}

  async getGarage(riderId: string): Promise<GarageVehicle[]> {
    return this.garageModel.find({ riderId }).exec();
  }

  async addVehicle(addVehicleDto: AddVehicleDto): Promise<GarageVehicle> {
    const existingVehicles = await this.getGarage(addVehicleDto.riderId);
    
    const newVehicle = new this.garageModel({
      ...addVehicleDto,
      isPrimary: existingVehicles.length === 0, // First vehicle is primary by default
    });
    
    return newVehicle.save();
  }

  async updateConfiguration(updateDto: UpdateConfigurationDto): Promise<GarageVehicle> {
    const vehicle = await this.garageModel.findById(updateDto.vehicleId);
    if (!vehicle || vehicle.riderId !== updateDto.riderId) {
      throw new NotFoundException('Vehicle not found in your garage');
    }

    vehicle.configuration = {
      ...vehicle.configuration,
      ...updateDto.configuration,
    };
    
    return vehicle.save();
  }

  async setPrimaryVehicle(setPrimaryDto: SetPrimaryVehicleDto): Promise<void> {
    // Unset all primary for this rider
    await this.garageModel.updateMany(
      { riderId: setPrimaryDto.riderId },
      { $set: { isPrimary: false } }
    );
    
    // Set new primary
    await this.garageModel.updateOne(
      { _id: setPrimaryDto.vehicleId, riderId: setPrimaryDto.riderId },
      { $set: { isPrimary: true } }
    );
  }

  async seedMockVehiclesIfEmpty(riderId: string): Promise<void> {
    const existing = await this.getGarage(riderId);
    if (existing.length === 0) {
      await this.addVehicle({
        riderId,
        vehicleId: 'yamaha_r1m_2024',
        make: 'Yamaha',
        model: 'YZF-R1M',
        year: 2024,
      });
      await this.addVehicle({
        riderId,
        vehicleId: 'ducati_panigale_v4s_2024',
        make: 'Ducati',
        model: 'Panigale V4 S',
        year: 2024,
      });
      await this.addVehicle({
        riderId,
        vehicleId: 'bmw_s1000rr_m_2024',
        make: 'BMW',
        model: 'S 1000 RR M',
        year: 2024,
      });
    }
  }
}
