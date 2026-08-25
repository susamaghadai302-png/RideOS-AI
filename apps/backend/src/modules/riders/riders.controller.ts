import { Controller, Get, Post, Delete, Patch, Param, Body, UseGuards, Req } from '@nestjs/common';
import { RidersService } from './riders.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AddBikeDto } from './dto/add-bike.dto';
import { UpdatePreferencesDto } from './dto/update-preferences.dto';

@Controller('riders')
@UseGuards(JwtAuthGuard)
export class RidersController {
  constructor(private readonly ridersService: RidersService) {}

  @Get('profile')
  async getProfile(@Req() req: any) {
    return this.ridersService.findById(req.user.userId);
  }

  @Post('garage')
  async addBike(@Req() req: any, @Body() dto: AddBikeDto) {
    return this.ridersService.addBike(req.user.userId, dto);
  }

  @Delete('garage/:bikeId')
  async deleteBike(@Req() req: any, @Param('bikeId') bikeId: string) {
    return this.ridersService.deleteBike(req.user.userId, bikeId);
  }

  @Patch('garage/:bikeId/primary')
  async setPrimaryBike(@Req() req: any, @Param('bikeId') bikeId: string) {
    return this.ridersService.setPrimaryBike(req.user.userId, bikeId);
  }

  @Post('preferences')
  async updatePreferences(@Req() req: any, @Body() dto: UpdatePreferencesDto) {
    return this.ridersService.updatePreferences(req.user.userId, dto);
  }

  @Delete('account')
  async deleteAccount(@Req() req: any) {
    return this.ridersService.deleteAccount(req.user.userId);
  }
}

