import { Injectable, NotFoundException, ForbiddenException, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { DiagnosticEvent, DiagnosticEventDocument } from './schemas/diagnostic_event.schema';
import { MaintenanceRecord, MaintenanceRecordDocument } from './schemas/maintenance_record.schema';
import { VehicleAlert, VehicleAlertDocument } from './schemas/vehicle_alert.schema';
import { VehicleDocument, VehicleDocumentDocument } from './schemas/vehicle_document.schema';
import {
  LogDiagnosticEventDto,
  CreateMaintenanceRecordDto,
  CreateVehicleAlertDto,
  CreateVehicleDocumentDto,
} from './dto/vehicle_health.dto';

@Injectable()
export class VehicleHealthService {
  private readonly logger = new Logger(VehicleHealthService.name);

  constructor(
    @InjectModel(DiagnosticEvent.name) private readonly diagnosticModel: Model<DiagnosticEventDocument>,
    @InjectModel(MaintenanceRecord.name) private readonly maintenanceModel: Model<MaintenanceRecordDocument>,
    @InjectModel(VehicleAlert.name) private readonly alertModel: Model<VehicleAlertDocument>,
    @InjectModel(VehicleDocument.name) private readonly documentModel: Model<VehicleDocumentDocument>,
  ) {}

  // 1. Diagnostics & Fault Code Management
  async logDiagnosticEvent(riderId: string, dto: LogDiagnosticEventDto): Promise<DiagnosticEventDocument> {
    const existing = await this.diagnosticModel.findOne({
      vehicleId: dto.vehicleId,
      code: dto.code,
      active: true,
    }).exec();

    if (existing) {
      existing.occurrences += 1;
      existing.lastSeen = new Date();
      existing.severity = dto.severity || existing.severity;
      existing.rawData = dto.rawData || existing.rawData;
      return existing.save();
    }

    const event = new this.diagnosticModel({
      ...dto,
      riderId,
      firstSeen: new Date(),
      lastSeen: new Date(),
      occurrences: 1,
      active: true,
      resolved: false,
    });
    return event.save();
  }

  async resolveDiagnosticEvent(riderId: string, eventId: string): Promise<DiagnosticEventDocument> {
    const event = await this.diagnosticModel.findById(eventId).exec();
    if (!event) throw new NotFoundException('Diagnostic event not found');
    if (event.riderId !== riderId) throw new ForbiddenException('Unauthorized access');

    event.active = false;
    event.resolved = true;
    event.resolvedAt = new Date();
    return event.save();
  }

  async getActiveDiagnostics(riderId: string, vehicleId: string): Promise<DiagnosticEventDocument[]> {
    return this.diagnosticModel.find({ riderId, vehicleId, active: true }).sort({ lastSeen: -1 }).exec();
  }

  async getDiagnosticHistory(riderId: string, vehicleId: string): Promise<DiagnosticEventDocument[]> {
    return this.diagnosticModel.find({ riderId, vehicleId }).sort({ firstSeen: -1 }).exec();
  }

  // 2. Maintenance Records
  async createMaintenanceRecord(riderId: string, dto: CreateMaintenanceRecordDto): Promise<MaintenanceRecordDocument> {
    const record = new this.maintenanceModel({
      ...dto,
      riderId,
      date: dto.date || new Date(),
    });
    return record.save();
  }

  async getMaintenanceHistory(riderId: string, vehicleId: string): Promise<MaintenanceRecordDocument[]> {
    return this.maintenanceModel.find({ riderId, vehicleId }).sort({ date: -1 }).exec();
  }

  // 3. Smart Vehicle Alerts
  async createOrUpdateAlert(riderId: string, dto: CreateVehicleAlertDto): Promise<VehicleAlertDocument> {
    const existing = await this.alertModel.findOne({
      vehicleId: dto.vehicleId,
      alertKey: dto.alertKey,
      status: { $in: ['NEW', 'ACTIVE'] },
    }).exec();

    if (existing) {
      existing.lastTriggered = new Date();
      existing.message = dto.message;
      existing.severity = dto.severity || existing.severity;
      return existing.save();
    }

    const alert = new this.alertModel({
      ...dto,
      riderId,
      status: 'ACTIVE',
      firstTriggered: new Date(),
      lastTriggered: new Date(),
    });
    return alert.save();
  }

  async acknowledgeAlert(riderId: string, alertId: string): Promise<VehicleAlertDocument> {
    const alert = await this.alertModel.findById(alertId).exec();
    if (!alert) throw new NotFoundException('Alert not found');
    if (alert.riderId !== riderId) throw new ForbiddenException('Unauthorized access');

    alert.status = 'ACKNOWLEDGED';
    alert.acknowledgedAt = new Date();
    return alert.save();
  }

  async resolveAlert(riderId: string, alertId: string): Promise<VehicleAlertDocument> {
    const alert = await this.alertModel.findById(alertId).exec();
    if (!alert) throw new NotFoundException('Alert not found');
    if (alert.riderId !== riderId) throw new ForbiddenException('Unauthorized access');

    alert.status = 'RESOLVED';
    alert.resolvedAt = new Date();
    return alert.save();
  }

  async getActiveAlerts(riderId: string, vehicleId: string): Promise<VehicleAlertDocument[]> {
    return this.alertModel.find({
      riderId,
      vehicleId,
      status: { $in: ['NEW', 'ACTIVE', 'ACKNOWLEDGED'] },
    }).sort({ lastTriggered: -1 }).exec();
  }

  // 4. Secure Vehicle Documents
  async createVehicleDocument(riderId: string, dto: CreateVehicleDocumentDto): Promise<VehicleDocumentDocument> {
    const doc = new this.documentModel({
      ...dto,
      riderId,
    });
    return doc.save();
  }

  async getVehicleDocuments(riderId: string, vehicleId: string): Promise<VehicleDocumentDocument[]> {
    return this.documentModel.find({ riderId, vehicleId }).sort({ createdAt: -1 }).exec();
  }

  async deleteVehicleDocument(riderId: string, documentId: string): Promise<{ deleted: boolean }> {
    const doc = await this.documentModel.findById(documentId).exec();
    if (!doc) throw new NotFoundException('Document not found');
    if (doc.riderId !== riderId) throw new ForbiddenException('Unauthorized access');

    await this.documentModel.findByIdAndDelete(documentId).exec();
    return { deleted: true };
  }

  // 5. Phase 7 Predictive Vehicle Health Summary
  async getPredictiveHealthSummary(riderId: string, vehicleId: string) {
    const activeDtcs = await this.getActiveDiagnostics(riderId, vehicleId);
    const activeAlerts = await this.getActiveAlerts(riderId, vehicleId);
    const maintenanceRecords = await this.getMaintenanceHistory(riderId, vehicleId);

    let healthScore: number | null = null;
    let status = 'UNAVAILABLE';

    if (activeDtcs.length > 0 || activeAlerts.length > 0) {
      healthScore = 100;
      if (activeDtcs.length > 0) healthScore -= activeDtcs.length * 15;
      if (activeAlerts.length > 0) healthScore -= activeAlerts.length * 5;
      healthScore = Math.max(20, Math.min(100, healthScore));
      status = healthScore >= 70 ? 'ATTENTION' : 'CRITICAL';
    }

    return {
      vehicleId,
      riderId,
      overallHealthScore: healthScore,
      status: status,
      activeDtcCount: activeDtcs.length,
      activeAlertCount: activeAlerts.length,
      lastServiceDate: maintenanceRecords.length > 0 ? maintenanceRecords[0].date : null,
      generatedAt: new Date().toISOString(),
    };
  }
}
