import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { TelemetrySample, TelemetrySampleDocument } from '../schemas/telemetry_sample.schema';
import { TelemetrySession, TelemetrySessionDocument } from '../schemas/telemetry_session.schema';

@Injectable()
export class TelemetryService {
  private readonly logger = new Logger(TelemetryService.name);
  
  // Basic batching queue
  private sampleBatch: any[] = [];
  private batchTimer: NodeJS.Timeout;

  constructor(
    @InjectModel(TelemetrySample.name) private sampleModel: Model<TelemetrySampleDocument>,
    @InjectModel(TelemetrySession.name) private sessionModel: Model<TelemetrySessionDocument>,
  ) {
    this.startBatchProcessor();
  }

  private startBatchProcessor() {
    this.batchTimer = setInterval(() => this.flushBatch(), 5000); // Flush every 5 seconds
  }

  async startSession(vehicleId: string): Promise<TelemetrySession> {
    const session = new this.sessionModel({
      vehicleId,
      startTime: new Date(),
    });
    return session.save();
  }

  async endSession(sessionId: string): Promise<TelemetrySession | null> {
    // Force flush any pending samples for this session
    await this.flushBatch();
    
    return this.sessionModel.findByIdAndUpdate(
      sessionId, 
      { endTime: new Date() },
      { new: true }
    ).exec();
  }

  ingestSample(sampleData: any) {
    this.sampleBatch.push(sampleData);
    if (this.sampleBatch.length >= 100) {
      this.flushBatch(); // Flush early if queue is full
    }
  }

  private async flushBatch() {
    if (this.sampleBatch.length === 0) return;
    
    const batchToInsert = [...this.sampleBatch];
    this.sampleBatch = [];
    
    try {
      await this.sampleModel.insertMany(batchToInsert);
      this.logger.debug(`Flushed ${batchToInsert.length} telemetry samples to DB.`);
    } catch (err) {
      this.logger.error('Failed to insert telemetry batch', err);
      // Re-queue on failure? Optional in production, avoiding for memory safety here.
    }
  }
}
