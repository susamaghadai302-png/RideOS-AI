import { Controller, Get, Post, Body, Put, Param, Delete, UseGuards, Req } from '@nestjs/common';
import { VehiclesService } from './vehicles.service';
import { CreateVehicleDto, UpdateVehicleDto } from './dto/vehicles.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Request } from 'express';

@Controller('vehicles')
@UseGuards(JwtAuthGuard)
export class VehiclesController {
  constructor(private readonly vehiclesService: VehiclesService) {}

  @Post()
  create(@Req() req: Request, @Body() createVehicleDto: CreateVehicleDto) {
    const userId = (req.user as any)?.userId || (req.user as any)?.sub;
    return this.vehiclesService.create(userId, createVehicleDto);
  }

  @Get()
  findAll(@Req() req: Request) {
    const userId = (req.user as any)?.userId || (req.user as any)?.sub;
    return this.vehiclesService.findAllActive(userId);
  }

  @Get(':id')
  findOne(@Req() req: Request, @Param('id') id: string) {
    const userId = (req.user as any)?.userId || (req.user as any)?.sub;
    return this.vehiclesService.findOne(id, userId);
  }

  @Put(':id')
  update(@Req() req: Request, @Param('id') id: string, @Body() updateVehicleDto: UpdateVehicleDto) {
    const userId = (req.user as any)?.userId || (req.user as any)?.sub;
    return this.vehiclesService.update(id, userId, updateVehicleDto);
  }

  @Delete(':id')
  remove(@Req() req: Request, @Param('id') id: string) {
    const userId = (req.user as any)?.userId || (req.user as any)?.sub;
    return this.vehiclesService.softDelete(id, userId);
  }
}
