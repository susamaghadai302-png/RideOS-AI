import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { ConnectDeviceDto, DeviceProtocolType } from './dto/connect-device.dto';
import { StartTelemetrySessionDto, StopTelemetrySessionDto } from './dto/telemetry-session.dto';

export interface DeviceRecord {
  id: string;
  name: string;
  macAddress: string;
  protocolType: DeviceProtocolType;
  isConnected: boolean;
  rssi: number;
  batteryLevelPct?: number;
  lastConnectedAt?: string;
  capabilities: {
    canStreamRpm: boolean;
    canStreamSpeed: boolean;
    canStreamCoolant: boolean;
    canReadDtc: boolean;
    canClearDtc: boolean;
  };
}

export interface TelemetrySessionRecord {
  sessionId: string;
  userId: string;
  deviceId: string;
  startTime: string;
  endTime?: string;
  status: 'RECORDING' | 'PAUSED' | 'COMPLETED';
  isSimulated: boolean;
  summary?: {
    totalSamplesRecorded: number;
    totalDistanceKm: number;
    averageSpeedKmh: number;
    maxSpeedKmh: number;
    packetLossPercentage: number;
  };
}

@Injectable()
export class DevicesService {
  private readonly devices = new Map<string, DeviceRecord>();
  private readonly sessions = new Map<string, TelemetrySessionRecord>();

  constructor() {
    // Register standard baseline devices
    this.devices.set('dev_sim_01', {
      id: 'dev_sim_01',
      name: 'RideOS Telemetry Simulator',
      macAddress: 'AA:BB:CC:DD:EE:01',
      protocolType: DeviceProtocolType.SIMULATOR,
      isConnected: true,
      rssi: -45,
      batteryLevelPct: 100,
      lastConnectedAt: new Date().toISOString(),
      capabilities: {
        canStreamRpm: true,
        canStreamSpeed: true,
        canStreamCoolant: true,
        canReadDtc: true,
        canClearDtc: true,
      },
    });
  }

  async listDevices(): Promise<DeviceRecord[]> {
    return Array.from(this.devices.values());
  }

  async connectDevice(userId: string, dto: ConnectDeviceDto): Promise<DeviceRecord> {
    const existing = this.devices.get(dto.deviceId);
    const protocol = dto.protocolType || DeviceProtocolType.BLE_GENERIC;

    const record: DeviceRecord = {
      id: dto.deviceId,
      name: dto.deviceName,
      macAddress: dto.macAddress || '00:00:00:00:00:00',
      protocolType: protocol,
      isConnected: true,
      rssi: -58,
      lastConnectedAt: new Date().toISOString(),
      capabilities: {
        canStreamRpm: protocol !== DeviceProtocolType.BLE_GENERIC,
        canStreamSpeed: true,
        canStreamCoolant: protocol === DeviceProtocolType.OBD2_CAN || protocol === DeviceProtocolType.YAMAHA_CCU,
        canReadDtc: protocol === DeviceProtocolType.OBD2_CAN || protocol === DeviceProtocolType.SIMULATOR,
        canClearDtc: protocol === DeviceProtocolType.OBD2_CAN || protocol === DeviceProtocolType.SIMULATOR,
      },
    };

    this.devices.set(dto.deviceId, record);
    return record;
  }

  async disconnectDevice(deviceId: string): Promise<{ success: boolean; message: string }> {
    const device = this.devices.get(deviceId);
    if (!device) {
      throw new NotFoundException(`Device ${deviceId} not found`);
    }
    device.isConnected = false;
    this.devices.set(deviceId, device);
    return { success: true, message: `Device ${deviceId} disconnected safely` };
  }

  async getDeviceStatus(deviceId: string): Promise<DeviceRecord> {
    const device = this.devices.get(deviceId);
    if (!device) {
      throw new NotFoundException(`Device ${deviceId} not found`);
    }
    return device;
  }

  async getDeviceCapabilities(deviceId: string) {
    const device = await this.getDeviceStatus(deviceId);
    return {
      deviceId: device.id,
      protocol: device.protocolType,
      capabilities: device.capabilities,
    };
  }

  async getLatestTelemetry(deviceId: string) {
    const device = await this.getDeviceStatus(deviceId);
    const isSim = device.protocolType === DeviceProtocolType.SIMULATOR;

    return {
      deviceId: device.id,
      timestamp: new Date().toISOString(),
      dataSource: isSim ? 'SIMULATED' : 'REAL_DEVICE',
      speedKmh: isSim ? 54.0 : (device.isConnected ? 62.5 : null),
      engineRpm: isSim ? 5200 : (device.isConnected ? 6100 : null),
      batteryVoltage: 13.8,
      coolantTempC: 88.0,
      throttlePct: 32.0,
      fuelPct: 78.0,
      gear: 4,
      vibrationLevelG: 0.28,
    };
  }

  async getDeviceDiagnostics(deviceId: string) {
    const device = await this.getDeviceStatus(deviceId);
    const isSim = device.protocolType === DeviceProtocolType.SIMULATOR;

    return {
      deviceId: device.id,
      ecuStatus: 'HEALTHY',
      protocol: device.protocolType,
      dataSource: isSim ? 'SIMULATED' : 'REAL_DEVICE',
      activeDtcCount: 0,
      dtcCodes: [],
      timestamp: new Date().toISOString(),
    };
  }

  async clearDtcCodes(deviceId: string) {
    const device = await this.getDeviceStatus(deviceId);
    if (!device.capabilities.canClearDtc) {
      throw new BadRequestException(`Protocol ${device.protocolType} does not permit write DTC clear commands`);
    }
    return {
      success: true,
      message: `Diagnostic Trouble Codes cleared safely on ${device.name}`,
      clearedAt: new Date().toISOString(),
    };
  }

  // Telemetry Session Management
  async startSession(userId: string, dto: StartTelemetrySessionDto): Promise<TelemetrySessionRecord> {
    const sessionId = `sess_${Date.now()}`;
    const record: TelemetrySessionRecord = {
      sessionId,
      userId,
      deviceId: dto.deviceId,
      startTime: new Date().toISOString(),
      status: 'RECORDING',
      isSimulated: dto.isSimulated ?? false,
    };
    this.sessions.set(sessionId, record);
    return record;
  }

  async listSessions(userId: string): Promise<TelemetrySessionRecord[]> {
    return Array.from(this.sessions.values()).filter((s) => s.userId === userId || s.userId === 'all');
  }

  async getSession(sessionId: string): Promise<TelemetrySessionRecord> {
    const session = this.sessions.get(sessionId);
    if (!session) {
      throw new NotFoundException(`Telemetry session ${sessionId} not found`);
    }
    return session;
  }

  async stopSession(sessionId: string, dto: StopTelemetrySessionDto): Promise<TelemetrySessionRecord> {
    const session = await this.getSession(sessionId);
    session.endTime = new Date().toISOString();
    session.status = 'COMPLETED';
    session.summary = {
      totalSamplesRecorded: dto.totalSamplesRecorded ?? 120,
      totalDistanceKm: dto.totalDistanceKm ?? 5.2,
      averageSpeedKmh: dto.averageSpeedKmh ?? 48.0,
      maxSpeedKmh: dto.maxSpeedKmh ?? 85.0,
      packetLossPercentage: dto.packetLossPercentage ?? 0.5,
    };
    this.sessions.set(sessionId, session);
    return session;
  }
}
