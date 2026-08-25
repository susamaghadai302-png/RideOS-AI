import { Controller, Get, Post, Body, Param } from '@nestjs/common';
import { MaintenanceService } from './maintenance.service';
import { MaintenanceTaskType } from '@rideos/vehicle';

@Controller('maintenance')
export class MaintenanceController {
  constructor(private readonly maintenanceService: MaintenanceService) {}

  @Get('bike/:bikeId')
  async getLogs(@Param('bikeId') bikeId: string) {
    return this.maintenanceService.getLogsForBike(bikeId);
  }

  @Post('log')
  async logService(
    @Body('bikeId') bikeId: string,
    @Body('taskType') taskType: MaintenanceTaskType,
    @Body('currentKm') currentKm: number,
    @Body('intervalKm') intervalKm?: number,
    @Body('notes') notes?: string,
  ) {
    return this.maintenanceService.logTask(
      bikeId,
      taskType,
      currentKm,
      intervalKm || 500,
      notes,
    );
  }
}
