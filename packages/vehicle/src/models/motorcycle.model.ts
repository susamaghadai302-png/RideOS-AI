export interface MotorcycleSpecs {
  bikeId: string;
  make: string;
  model: string;
  year: number;
  engineCC: number;
  wetWeightKg?: number;
  maxLeanAngleLimitDegrees?: number;
  frontTirePressureRecommendedPsi: number;
  rearTirePressureRecommendedPsi: number;
  isPrimary: boolean;
}
