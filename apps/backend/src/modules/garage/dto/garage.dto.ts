export class AddVehicleDto {
  riderId: string;
  vehicleId: string;
  make: string;
  model: string;
  year: number;
}

export class UpdateConfigurationDto {
  riderId: string;
  vehicleId: string; // The ID of the document to update
  configuration: Record<string, any>;
}

export class SetPrimaryVehicleDto {
  riderId: string;
  vehicleId: string;
}
