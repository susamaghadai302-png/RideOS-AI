import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Rider, RiderDocument } from './schemas/rider.schema';
import { AddBikeDto } from './dto/add-bike.dto';
import { UpdatePreferencesDto } from './dto/update-preferences.dto';
import { randomUUID } from 'crypto';

@Injectable()
export class RidersService {
  constructor(
    @InjectModel(Rider.name) private readonly riderModel: Model<RiderDocument>,
  ) {}

  async findByEmail(email: string): Promise<RiderDocument | null> {
    return this.riderModel.findOne({ email }).exec();
  }

  async findById(id: string): Promise<RiderDocument> {
    const rider = await this.riderModel.findById(id).select('-passwordHash').exec();
    if (!rider) {
      throw new NotFoundException(`Rider with ID ${id} not found`);
    }
    return rider;
  }

  async addBike(riderId: string, dto: AddBikeDto): Promise<RiderDocument> {
    const rider = await this.riderModel.findById(riderId);
    if (!rider) {
      throw new NotFoundException('Rider not found');
    }

    const newBike = {
      bikeId: randomUUID(),
      make: dto.make,
      model: dto.model,
      year: dto.year,
      engineCC: dto.engineCC,
      maxLeanAngleLimit: dto.maxLeanAngleLimit || 45.0,
      isPrimary: dto.isPrimary || rider.garage.length === 0,
    };

    if (newBike.isPrimary) {
      rider.garage.forEach((b) => (b.isPrimary = false));
    }

    rider.garage.push(newBike as any);
    await rider.save();
    return this.findById(riderId);
  }

  async deleteBike(riderId: string, bikeId: string): Promise<RiderDocument> {
    const rider = await this.riderModel.findById(riderId);
    if (!rider) {
      throw new NotFoundException('Rider not found');
    }

    rider.garage = rider.garage.filter((b) => b.bikeId !== bikeId);
    if (rider.garage.length > 0 && !rider.garage.some((b) => b.isPrimary)) {
      rider.garage[0].isPrimary = true;
    }

    await rider.save();
    return this.findById(riderId);
  }

  async setPrimaryBike(riderId: string, bikeId: string): Promise<RiderDocument> {
    const rider = await this.riderModel.findById(riderId);
    if (!rider) {
      throw new NotFoundException('Rider not found');
    }

    rider.garage.forEach((b) => {
      b.isPrimary = b.bikeId === bikeId;
    });

    await rider.save();
    return this.findById(riderId);
  }

  async updatePreferences(riderId: string, dto: UpdatePreferencesDto): Promise<RiderDocument> {
    const rider = await this.riderModel.findById(riderId);
    if (!rider) {
      throw new NotFoundException('Rider not found');
    }

    rider.preferences = {
      ...rider.preferences,
      ...dto,
    } as any;

    await rider.save();
    return this.findById(riderId);
  }

  async deleteAccount(riderId: string): Promise<{ deleted: boolean; message: string }> {
    const rider = await this.riderModel.findById(riderId);
    if (!rider) {
      throw new NotFoundException('Rider account not found');
    }

    await this.riderModel.findByIdAndDelete(riderId).exec();
    return {
      deleted: true,
      message: 'Account and associated vehicle profile data permanently deleted',
    };
  }
}


