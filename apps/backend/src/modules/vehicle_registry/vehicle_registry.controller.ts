import { Controller, Get, Param, Query, Post, Body } from '@nestjs/common';
import { VehicleRegistryService } from './vehicle_registry.service';

@Controller('vehicle-registry')
export class VehicleRegistryController {
  constructor(private readonly registryService: VehicleRegistryService) {}

  @Get()
  async getAllVehicles() {
    return this.registryService.findAll();
  }

  @Get('catalog/version')
  getCatalogVersion() {
    return this.registryService.getCatalogVersion();
  }

  @Get('catalog/manufacturers')
  async getManufacturers() {
    return this.registryService.getManufacturers();
  }

  @Get('catalog/tree')
  async getCatalogTree() {
    return this.registryService.getCatalogTree();
  }

  @Get('resolve')
  async resolveVehicle(
    @Query('name') name?: string,
    @Query('deviceName') deviceName?: string,
    @Query('services') services?: string
  ) {
    const targetName = name || deviceName || '';
    const serviceList = services ? services.split(',') : [];
    const match = await this.registryService.resolveByBluetooth(targetName, serviceList);
    return match || {};
  }

  @Get(':id')
  async getById(@Param('id') id: string) {
    return this.registryService.findById(id);
  }

  @Get('search/query')
  async search(
    @Query('manufacturer') manufacturer?: string,
    @Query('model') model?: string,
    @Query('year') year?: string,
  ) {
    return this.registryService.search(
      manufacturer, 
      model, 
      year ? parseInt(year, 10) : undefined
    );
  }

  @Post('unverified')
  async createUnverified(@Body() data: any) {
    return this.registryService.createUnverified(data);
  }
}

