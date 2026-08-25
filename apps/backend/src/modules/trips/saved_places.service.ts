import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { SavedPlace, SavedPlaceDocument } from './schemas/saved_place.schema';
import { CreateSavedPlaceDto } from './dto/create-trip.dto';

@Injectable()
export class SavedPlacesService {
  constructor(
    @InjectModel(SavedPlace.name) private readonly savedPlaceModel: Model<SavedPlaceDocument>,
  ) {}

  async getSavedPlaces(riderId: string): Promise<SavedPlaceDocument[]> {
    return this.savedPlaceModel.find({ riderId }).sort({ createdAt: -1 }).exec();
  }

  async createSavedPlace(riderId: string, dto: CreateSavedPlaceDto): Promise<SavedPlaceDocument> {
    const existing = await this.savedPlaceModel.findOne({ riderId, name: dto.name }).exec();
    if (existing) {
      existing.category = dto.category;
      existing.lat = dto.lat;
      existing.lng = dto.lng;
      existing.address = dto.address || existing.address;
      existing.icon = dto.icon || existing.icon;
      return existing.save();
    }

    const place = new this.savedPlaceModel({
      ...dto,
      riderId,
    });
    return place.save();
  }

  async deleteSavedPlace(riderId: string, placeId: string): Promise<{ deleted: boolean }> {
    const place = await this.savedPlaceModel.findById(placeId).exec();
    if (!place) {
      throw new NotFoundException(`Saved place not found`);
    }
    if (place.riderId !== riderId) {
      throw new ForbiddenException('Unauthorized access to this saved place');
    }
    await this.savedPlaceModel.findByIdAndDelete(placeId).exec();
    return { deleted: true };
  }
}
