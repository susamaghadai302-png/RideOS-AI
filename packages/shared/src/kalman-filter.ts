/**
   * 1D Kalman Filter for smoothing GPS speed, altitude, and position jitter
   */
export class KalmanFilter {
  private q: number; // Process noise covariance
  private r: number; // Measurement noise covariance
  private x: number; // Estimated value
  private p: number; // Estimation error covariance
  private k: number = 0; // Kalman gain

  constructor(processNoise: number = 1, measurementNoise: number = 4, error: number = 1) {
    this.q = processNoise;
    this.r = measurementNoise;
    this.p = error;
    this.x = 0;
  }

  public filter(measurement: number): number {
    // Prediction update
    this.p = this.p + this.q;

    // Measurement update
    this.k = this.p / (this.p + this.r);
    this.x = this.x + this.k * (measurement - this.x);
    this.p = (1 - this.k) * this.p;

    return this.x;
  }

  public getState(): number {
    return this.x;
  }
}
