import { Controller, Get, Post, Delete, Param, Body, UseGuards, Req } from '@nestjs/common';
import { SavedPlacesService } from './saved_places.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CreateSavedPlaceDto } from './dto/create-trip.dto';

@Controller('saved-places')
@UseGuards(JwtAuthGuard)
export class SavedPlacesController {
  constructor(private readonly savedPlacesService: SavedPlacesService) {}

  @Get()
  async getSavedPlaces(@Req() req: any) {
    return this.savedPlacesService.getSavedPlaces(req.user.userId);
  }

  @Post()
  async createSavedPlace(@Req() req: any, @Body() dto: CreateSavedPlaceDto) {
    return this.savedPlacesService.createSavedPlace(req.user.userId, dto);
  }

  @Delete(':id')
  async deleteSavedPlace(@Req() req: any, @Param('id') id: string) {
    return this.savedPlacesService.deleteSavedPlace(req.user.userId, id);
  }
}
