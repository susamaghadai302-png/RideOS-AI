import { Injectable, ForbiddenException, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { DiagnosticScan, DiagnosticScanDocument } from './schemas/diagnostic-scan.schema';
import { SubmitDiagnosticScanDto } from './dto/diagnostic-scan.dto';
import { VehiclesService } from '../vehicles/vehicles.service';
import { DiagnosticsDecoder } from './diagnostics.decoder';

@Injectable()
export class DiagnosticsService {
  constructor(
    @InjectModel(DiagnosticScan.name) private diagnosticScanModel: Model<DiagnosticScanDocument>,
    private vehiclesService: VehiclesService,
    private decoder: DiagnosticsDecoder,
  ) {}

  async submitScan(ownerId: string, vehicleId: string, submitScanDto: SubmitDiagnosticScanDto): Promise<DiagnosticScan> {
    // 1. Verify ownership. Will throw if not found or not owned.
    await this.vehiclesService.findOne(vehicleId, ownerId);

    // 2. Decode raw payloads into authoritative faults
    const faults = submitScanDto.rawPayloads ? this.decoder.decodeDtcs(submitScanDto.rawPayloads) : [];

    const newScan = new this.diagnosticScanModel({
      scannedVin: submitScanDto.scannedVin,
      transportType: submitScanDto.transportType,
      protocol: submitScanDto.protocol,
      faults,
      isClearCommand: false,
      vehicleId: new Types.ObjectId(vehicleId),
      ownerId,
    });

    return newScan.save();
  }

  async getScansForVehicle(ownerId: string, vehicleId: string): Promise<DiagnosticScan[]> {
    // 1. Verify ownership
    await this.vehiclesService.findOne(vehicleId, ownerId);

    // 2. Fetch scans ordered by newest first
    return this.diagnosticScanModel.find({ vehicleId: new Types.ObjectId(vehicleId), ownerId })
      .sort({ createdAt: -1 })
      .limit(50)
      .exec();
  }

  async clearDtcs(ownerId: string, vehicleId: string, transportType: string, protocol: string, speedPayload: string, clearAckPayload: string): Promise<DiagnosticScan> {
    // 1. Verify ownership
    await this.vehiclesService.findOne(vehicleId, ownerId);

    // 2. Verify safety interlock (speed == 0) and ECU acknowledgement
    this.decoder.verifyClearCommand(speedPayload, clearAckPayload);

    // 3. Record the clear command as a specialized scan
    const newScan = new this.diagnosticScanModel({
      vehicleId: new Types.ObjectId(vehicleId),
      ownerId,
      transportType,
      protocol,
      faults: [],
      isClearCommand: true,
    });

    return newScan.save();
  }
}
