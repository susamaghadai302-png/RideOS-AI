import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { DiagnosticLog, DiagnosticLogDocument } from './schemas/diagnostic-log.schema';
import { StreamObdDataDto } from './dto/obd-data.dto';

const DTC_DATABASE: Record<string, { description: string; severity: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL' }> = {
  P0300: { description: 'Random/Multiple Cylinder Misfire Detected', severity: 'HIGH' },
  P0117: { description: 'Engine Coolant Temperature Sensor 1 Circuit Low', severity: 'MEDIUM' },
  P0562: { description: 'System Voltage Low (< 11.5V)', severity: 'HIGH' },
  P0122: { description: 'Throttle Position Sensor Circuit Low Input', severity: 'MEDIUM' },
};

@Injectable()
export class ObdDiagnosticsService {
  constructor(
    @InjectModel(DiagnosticLog.name) private readonly logModel: Model<DiagnosticLogDocument>,
  ) {}

  async processObdData(riderId: string, dto: StreamObdDataDto): Promise<DiagnosticLogDocument> {
    let tpmsWarning = false;
    let tpmsMessage = '';

    if (dto.frontTirePsi < 28.0 || dto.rearTirePsi < 28.0) {
      tpmsWarning = true;
      tpmsMessage = `LOW TIRE PRESSURE WARNING: Front ${dto.frontTirePsi} PSI | Rear ${dto.rearTirePsi} PSI`;
    }

    const newLog = new this.logModel({
      riderId,
      rpm: dto.rpm,
      engineTempC: dto.engineTempC,
      throttlePct: dto.throttlePct,
      batteryVoltage: dto.batteryVoltage,
      frontTirePsi: dto.frontTirePsi,
      rearTirePsi: dto.rearTirePsi,
      diagnosticCodes: dto.diagnosticCodes,
      tpmsWarning,
      tpmsMessage,
    });

    return newLog.save();
  }

  async getLatestDiagnostics(riderId: string) {
    const log = await this.logModel.findOne({ riderId }).sort({ createdAt: -1 }).exec();
    if (!log) {
      return {
        riderId,
        dtcList: [],
        tpmsWarning: false,
        tpmsMessage: 'No diagnostic logs found',
      };
    }

    const dtcList = log.diagnosticCodes.map((code) => {
      const info = DTC_DATABASE[code] || { description: 'Unknown Diagnostic Fault Code', severity: 'LOW' };
      return {
        code,
        description: info.description,
        severity: info.severity,
      };
    });

    return {
      reportId: log._id,
      riderId: log.riderId,
      rpm: log.rpm,
      engineTempC: log.engineTempC,
      batteryVoltage: log.batteryVoltage,
      frontTirePsi: log.frontTirePsi,
      rearTirePsi: log.rearTirePsi,
      dtcList,
      tpmsWarning: log.tpmsWarning,
      tpmsMessage: log.tpmsMessage,
      createdAt: (log as any).createdAt,
    };
  }
}
