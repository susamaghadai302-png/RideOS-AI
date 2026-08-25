import { Injectable } from '@nestjs/common';
import { MaintenanceLog, MaintenanceTaskType } from '@rideos/vehicle';

@Injectable()
export class MaintenanceService {
  private readonly logs: MaintenanceLog[] = [
    {
      id: 'maint-1',
      bikeId: 'bike-001',
      taskType: 'CHAIN_LUBE',
      performedAtKm: 12000,
      performedAtDate: new Date().toISOString(),
      nextDueKm: 12500,
      isCompleted: true,
      notes: 'Cleaned with degreaser and applied synthetic chain lube',
    },
    {
      id: 'maint-2',
      bikeId: 'bike-001',
      taskType: 'OIL_CHANGE',
      performedAtKm: 10000,
      performedAtDate: new Date().toISOString(),
      nextDueKm: 15000,
      isCompleted: true,
      notes: 'Replaced oil filter & 10W-40 full synthetic oil',
    },
  ];

  async getLogsForBike(bikeId: string): Promise<MaintenanceLog[]> {
    return this.logs.filter((log) => log.bikeId === bikeId);
  }

  async logTask(
    bikeId: string,
    taskType: MaintenanceTaskType,
    currentOdometerKm: number,
    intervalKm: number = 500,
    notes?: string,
  ): Promise<MaintenanceLog> {
    const newLog: MaintenanceLog = {
      id: `maint-${Date.now()}`,
      bikeId,
      taskType,
      performedAtKm: currentOdometerKm,
      performedAtDate: new Date().toISOString(),
      nextDueKm: currentOdometerKm + intervalKm,
      isCompleted: true,
      notes,
    };
    this.logs.push(newLog);
    return newLog;
  }
}
