import { Controller, Get, Post, Body, Param, Put } from '@nestjs/common';
import { GarageService } from './garage.service';
import { AddVehicleDto, UpdateConfigurationDto, SetPrimaryVehicleDto } from './dto/garage.dto';

@Controller('api/v1/garage')
export class GarageController {
  constructor(private readonly garageService: GarageService) {}

  @Get(':riderId')
  async getGarage(@Param('riderId') riderId: string) {
    return this.garageService.getGarage(riderId);
  }

  @Post('add')
  async addVehicle(@Body() addVehicleDto: AddVehicleDto) {
    return this.garageService.addVehicle(addVehicleDto);
  }

  @Put('configuration')
  async updateConfiguration(@Body() updateDto: UpdateConfigurationDto) {
    return this.garageService.updateConfiguration(updateDto);
  }

  @Post('primary')
  async setPrimaryVehicle(@Body() setPrimaryDto: SetPrimaryVehicleDto) {
    await this.garageService.setPrimaryVehicle(setPrimaryDto);
    return { success: true };
  }
}
