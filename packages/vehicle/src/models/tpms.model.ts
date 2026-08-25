export interface TpmsSensorReadings {
  bikeId: string;
  timestamp: string;
  frontPsi: number;
  rearPsi: number;
  frontTempCelsius: number;
  rearTempCelsius: number;
  isFrontLow: boolean;
  isRearLow: boolean;
}
