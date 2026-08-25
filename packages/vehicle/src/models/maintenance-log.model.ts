export type MaintenanceTaskType =
  | 'OIL_CHANGE'
  | 'CHAIN_LUBE'
  | 'CHAIN_TENSION'
  | 'BRAKE_PADS'
  | 'TIRE_CHANGE'
  | 'SPARK_PLUGS'
  | 'VALVE_CLEARANCE';

export interface MaintenanceLog {
  id: string;
  bikeId: string;
  taskType: MaintenanceTaskType;
  performedAtKm: number;
  performedAtDate: string;
  nextDueKm: number;
  nextDueDate?: string;
  notes?: string;
  isCompleted: boolean;
}
