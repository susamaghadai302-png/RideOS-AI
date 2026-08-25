import { Controller, Get, Query } from '@nestjs/common';
import { DiscoveryService } from './discovery.service';

@Controller('discovery')
export class DiscoveryController {
  constructor(private readonly discoveryService: DiscoveryService) {}

  @Get('routes')
  async getRoutes(@Query('difficulty') difficulty?: string) {
    return this.discoveryService.getCuratedRoutes(difficulty);
  }
}
