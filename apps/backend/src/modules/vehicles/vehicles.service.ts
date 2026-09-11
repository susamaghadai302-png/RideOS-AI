import { Injectable, NotFoundException, BadRequestException, ForbiddenException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { UserVehicle, UserVehicleDocument } from './schemas/user-vehicle.schema';
import { CreateVehicleDto, UpdateVehicleDto } from './dto/vehicles.dto';

@Injectable()
export class VehiclesService {
  constructor(
    @InjectModel(UserVehicle.name) private vehicleModel: Model<UserVehicleDocument>,
  ) {}

  async create(ownerId: string, createVehicleDto: CreateVehicleDto): Promise<UserVehicle> {
    if (createVehicleDto.vin) {
      const existing = await this.vehicleModel.findOne({ vin: createVehicleDto.vin });
      if (existing) {
        throw new BadRequestException('Vehicle with this VIN is already registered.');
      }
    }

    const existingVehiclesCount = await this.vehicleModel.countDocuments({ ownerId, isActive: true });

    const newVehicle = new this.vehicleModel({
      ...createVehicleDto,
      ownerId,
      isPrimary: existingVehiclesCount === 0, // Make primary if it's the first vehicle
    });

    return newVehicle.save();
  }

  async findAllActive(ownerId: string): Promise<UserVehicle[]> {
    return this.vehicleModel.find({ ownerId, isActive: true }).exec();
  }

  async findOne(id: string, ownerId: string): Promise<UserVehicleDocument> {
    const vehicle = await this.vehicleModel.findOne({ _id: id, ownerId, isActive: true }).exec();
    if (!vehicle) {
      throw new NotFoundException('Vehicle not found');
    }
    return vehicle;
  }

  async update(id: string, ownerId: string, updateVehicleDto: UpdateVehicleDto): Promise<UserVehicle> {
    const vehicle = await this.findOne(id, ownerId); // enforces ownership & existence
    
    // If setting primary, unset others
    if (updateVehicleDto.isPrimary === true) {
      await this.vehicleModel.updateMany({ ownerId }, { $set: { isPrimary: false } });
    }

    Object.assign(vehicle, updateVehicleDto);
    return vehicle.save();
  }

  async softDelete(id: string, ownerId: string): Promise<void> {
    const vehicle = await this.findOne(id, ownerId);
    vehicle.isActive = false;
    vehicle.isPrimary = false;
    await vehicle.save();

    // Re-assign primary if necessary
    const otherActive = await this.vehicleModel.findOne({ ownerId, isActive: true }).exec();
    if (otherActive) {
      otherActive.isPrimary = true;
      await otherActive.save();
    }
  }
}
