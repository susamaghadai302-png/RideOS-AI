import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { VehicleModel, VehicleModelDocument } from './schemas/vehicle_model.schema';

@Injectable()
export class VehicleRegistryService {
  private readonly logger = new Logger(VehicleRegistryService.name);

  constructor(
    @InjectModel(VehicleModel.name) private vehicleModel: Model<VehicleModelDocument>,
  ) {}

  async findAll(): Promise<VehicleModel[]> {
    return this.vehicleModel.find().exec();
  }

  async findById(id: string): Promise<VehicleModel | null> {
    return this.vehicleModel.findById(id).exec();
  }

  async search(manufacturer?: string, model?: string, year?: number): Promise<VehicleModel[]> {
    const query: any = {};
    if (manufacturer) query.manufacturer = { $regex: new RegExp(manufacturer, 'i') };
    if (model) query.model = { $regex: new RegExp(model, 'i') };
    if (year) query.year = year;
    return this.vehicleModel.find(query).exec();
  }

  async createUnverified(data: Partial<VehicleModel>): Promise<VehicleModel> {
    const newVehicle = new this.vehicleModel({
      ...data,
      category: data.category || 'Unknown',
      protocolAdapter: data.protocolAdapter || 'generic_ble',
      thumbnailUrl: data.thumbnailUrl || 'assets/garage/thumbs/generic_bike.png',
      model3DUrl: data.model3DUrl || '',
    });
    return newVehicle.save();
  }

  async resolveByBluetooth(deviceName: string, advertisedServices: string[]): Promise<VehicleModel | null> {
    if (!deviceName && (!advertisedServices || advertisedServices.length === 0)) {
      return null;
    }

    const query: any = { $or: [] };
    
    if (deviceName) {
      query.$or.push({
        bluetoothIdentifiers: { $elemMatch: { $regex: new RegExp(`^${deviceName}`, 'i') } }
      });
    }

    if (advertisedServices && advertisedServices.length > 0) {
      query.$or.push({
        'bleServices.serviceUuid': { $in: advertisedServices }
      });
    }

    if (query.$or.length === 0) return null;

    const match = await this.vehicleModel.findOne(query).exec();
    return match;
  }

  async seedDemoRegistry(): Promise<void> {
    const count = await this.vehicleModel.countDocuments();
    if (count > 0) return;

    this.logger.log('Seeding Vehicle Registry with comprehensive motorcycle and scooter taxonomy...');
    
    await this.vehicleModel.insertMany([
      // --- SCOOTERS ---
      {
        manufacturer: 'Suzuki',
        model: 'Burgman Street 125',
        variant: 'EX',
        year: 2025,
        category: 'Scooter',
        fuelType: 'Petrol',
        bluetoothIdentifiers: ['SUZUKI_BURGMAN', 'SUZ_BT_RIDE', 'BURGMAN_EX'],
        protocolAdapter: 'suzuki_snet',
        supportedFunctions: ['read_speed', 'read_battery', 'read_trip', 'read_fuel'],
        model3DUrl: 'assets/models/suzuki_burgman.glb',
        thumbnailUrl: 'assets/garage/suzuki_burgman.png',
        specifications: {
          engineCc: 124,
          powerBhp: 8.6,
          torqueNm: 10.0,
          curbWeightKg: 111,
          topSpeedKmh: 95,
          fuelCapacityL: 5.5,
          transmission: 'CVT',
        },
        maintenanceIntervals: {
          engine_oil: { km: 4000, months: 6, description: 'Engine Oil & Filter' },
          drive_belt: { km: 12000, months: 24, description: 'CVT Drive Belt Inspection' },
          final_drive_gear_oil: { km: 8000, months: 12, description: 'Transmission Gear Oil' },
        }
      },
      {
        manufacturer: 'Honda',
        model: 'Activa 6G',
        variant: 'H-Smart',
        year: 2024,
        category: 'Scooter',
        fuelType: 'Petrol',
        bluetoothIdentifiers: ['HONDA_SMART', 'ACTIVA_6G', 'HONDA_ROADSYNC'],
        protocolAdapter: 'honda_roadsync',
        supportedFunctions: ['read_speed', 'read_battery', 'read_fuel', 'read_odometer'],
        model3DUrl: '',
        thumbnailUrl: 'assets/garage/thumbs/honda_activa.png',
        specifications: {
          engineCc: 109.5,
          powerBhp: 7.7,
          torqueNm: 8.9,
          curbWeightKg: 106,
          topSpeedKmh: 85,
          fuelCapacityL: 5.3,
          transmission: 'V-Matic CVT',
        },
        maintenanceIntervals: {
          engine_oil: { km: 3000, months: 6, description: 'Engine Oil Replacement' },
          air_filter: { km: 6000, months: 12, description: 'Air Cleaner Element' },
        }
      },
      {
        manufacturer: 'TVS',
        model: 'Ntorq 125',
        variant: 'Race XP',
        year: 2024,
        category: 'Scooter',
        fuelType: 'Petrol',
        bluetoothIdentifiers: ['TVS_SMARTXONNECT', 'NTORQ_RACE_XP', 'TVS_NTORQ'],
        protocolAdapter: 'tvs_smartxonnect',
        supportedFunctions: ['read_speed', 'read_rpm', 'read_engine_temp', 'read_lap_timer', 'read_lean_angle'],
        model3DUrl: '',
        thumbnailUrl: 'assets/garage/thumbs/tvs_ntorq.png',
        specifications: {
          engineCc: 124.8,
          powerBhp: 10.0,
          torqueNm: 10.8,
          curbWeightKg: 116,
          topSpeedKmh: 98,
          fuelCapacityL: 5.8,
          transmission: 'CVT',
        },
        maintenanceIntervals: {
          engine_oil: { km: 3000, months: 4, description: 'Engine Oil & Strainer' },
          spark_plug: { km: 12000, months: 12, description: 'Spark Plug Gap/Replace' },
        }
      },
      {
        manufacturer: 'Yamaha',
        model: 'Aerox 155',
        variant: 'Connected Version S',
        year: 2024,
        category: 'Scooter',
        fuelType: 'Petrol',
        bluetoothIdentifiers: ['YAMAHA_CCU', 'AEROX_155', 'Y-CONNECT_AEROX'],
        protocolAdapter: 'yamaha_y_connect',
        supportedFunctions: ['read_speed', 'read_rpm', 'read_battery', 'read_fuel', 'read_malfunction', 'read_oil_maintenance'],
        model3DUrl: '',
        thumbnailUrl: 'assets/garage/thumbs/yamaha_aerox.png',
        specifications: {
          engineCc: 155,
          powerBhp: 14.8,
          torqueNm: 13.9,
          curbWeightKg: 126,
          topSpeedKmh: 120,
          fuelCapacityL: 5.5,
          transmission: 'V-Belt Automatic',
        },
        maintenanceIntervals: {
          engine_oil: { km: 4000, months: 6, description: 'Yamalube Synthetic Oil' },
          v_belt: { km: 20000, months: 24, description: 'V-Belt Replacement' },
        }
      },

      // --- MOTORCYCLES ---
      {
        manufacturer: 'Yamaha',
        model: 'MT-09 SP',
        variant: 'SP Performance',
        year: 2024,
        category: 'Motorcycle',
        fuelType: 'Petrol',
        bluetoothIdentifiers: ['YAMAHA_CCU', 'YAM_MT09', 'MT09_SP_CCU'],
        protocolAdapter: 'yamaha_y_connect',
        supportedFunctions: ['read_speed', 'read_rpm', 'read_temp', 'read_lean_angle', 'read_throttle', 'read_gear'],
        model3DUrl: 'assets/models/yamaha_mt09_sp.glb',
        thumbnailUrl: 'assets/garage/yamaha_mt09_sp.png',
        specifications: {
          engineCc: 890,
          powerBhp: 117.3,
          torqueNm: 93.0,
          curbWeightKg: 190,
          topSpeedKmh: 225,
          fuelCapacityL: 14.0,
          transmission: '6-speed with Quick Shift System',
        },
        maintenanceIntervals: {
          engine_oil: { km: 5000, months: 6, description: 'Engine Oil & Filter Service' },
          spark_plug: { km: 15000, months: 18, description: 'Spark Plugs Inspection' },
        }
      },
      {
        manufacturer: 'Yamaha',
        model: 'YZF-R1M',
        variant: 'Carbon Special Edition',
        year: 2024,
        category: 'Motorcycle',
        fuelType: 'Petrol',
        bluetoothIdentifiers: ['YAMAHA_CCU', 'YAM_R1M', 'R1M_TELEMETRY'],
        protocolAdapter: 'yamaha_y_connect',
        supportedFunctions: ['read_speed', 'read_rpm', 'read_temp', 'read_lean_angle', 'read_throttle', 'read_gear', 'read_brake_pressure'],
        model3DUrl: '',
        thumbnailUrl: 'assets/garage/yamaha_r1m.png',
        specifications: {
          engineCc: 998,
          powerBhp: 197.0,
          torqueNm: 113.3,
          curbWeightKg: 202,
          topSpeedKmh: 299,
          fuelCapacityL: 17.0,
          transmission: '6-speed with Quickshifter',
        },
        maintenanceIntervals: {
          engine_oil: { km: 5000, months: 6, description: 'Racing Engine Oil & Filter' },
          valve_clearance: { km: 40000, months: 48, description: 'Valve Clearance Check' },
          brake_fluid: { km: 10000, months: 12, description: 'DOT 4 Racing Brake Fluid' },
        }
      },
      {
        manufacturer: 'Ducati',
        model: 'Panigale V4',
        variant: 'S',
        year: 2024,
        category: 'Motorcycle',
        fuelType: 'Petrol',
        bluetoothIdentifiers: ['DUCATI_DMS', 'PANIGALE_V4', 'DUCATI_BT'],
        protocolAdapter: 'ducati_dms',
        supportedFunctions: ['read_speed', 'read_rpm', 'read_temp', 'read_lean_angle', 'read_traction_control', 'read_abs_status'],
        model3DUrl: 'assets/models/ducati_panigale.glb',
        thumbnailUrl: 'assets/garage/ducati_panigale.png',
        specifications: {
          engineCc: 1103,
          powerBhp: 215.5,
          torqueNm: 123.6,
          curbWeightKg: 195.5,
          topSpeedKmh: 315,
          fuelCapacityL: 17.0,
          transmission: '6-speed DQS EVO 2',
        },
        maintenanceIntervals: {
          desmo_service: { km: 24000, months: 36, description: 'Desmo Valve Clearance Service' },
          oil_service: { km: 12000, months: 12, description: 'Shell Advance Ultra Oil Service' },
        }
      },
      {
        manufacturer: 'BMW Motorrad',
        model: 'M 1000 RR',
        variant: 'M Competition',
        year: 2024,
        category: 'Motorcycle',
        fuelType: 'Petrol',
        bluetoothIdentifiers: ['BMW_CONNECT', 'M1000RR_M', 'BMW_MOTORRAD_BT'],
        protocolAdapter: 'bmw_motorrad_connect',
        supportedFunctions: ['read_speed', 'read_rpm', 'read_temp', 'read_tire_pressure', 'read_lean_angle', 'read_riding_mode'],
        model3DUrl: 'assets/models/bmw_m1000rr.glb',
        thumbnailUrl: 'assets/garage/bmw_m1000rr.png',
        specifications: {
          engineCc: 999,
          powerBhp: 212.0,
          torqueNm: 113.0,
          curbWeightKg: 192.0,
          topSpeedKmh: 314,
          fuelCapacityL: 16.5,
          transmission: '6-speed ShiftCam with Pro Shift',
        },
        maintenanceIntervals: {
          break_in_service: { km: 1000, months: 1, description: 'Initial Break-In Inspection' },
          annual_service: { km: 10000, months: 12, description: 'BMW Advantec Ultimate Oil & Inspection' },
        }
      },
      {
        manufacturer: 'Royal Enfield',
        model: 'Classic 350',
        variant: 'Dark Stealth Black',
        year: 2024,
        category: 'Motorcycle',
        fuelType: 'Petrol',
        bluetoothIdentifiers: ['RE_TRIPPER', 'ENFIELD_BT', 'ROYAL_ENFIELD'],
        protocolAdapter: 'royal_enfield_tripper',
        supportedFunctions: ['read_speed', 'read_odometer', 'read_trip', 'read_battery_voltage'],
        model3DUrl: '',
        thumbnailUrl: 'assets/garage/thumbs/re_classic350.png',
        specifications: {
          engineCc: 349,
          powerBhp: 20.2,
          torqueNm: 27.0,
          curbWeightKg: 195,
          topSpeedKmh: 115,
          fuelCapacityL: 13.0,
          transmission: '5-speed Constant Mesh',
        },
        maintenanceIntervals: {
          engine_oil: { km: 5000, months: 6, description: 'Semi-Synthetic Engine Oil & Filter' },
          tappet_inspection: { km: 10000, months: 12, description: 'Valve Tappet Adjustment' },
        }
      },
      {
        manufacturer: 'KTM',
        model: '390 Duke',
        variant: 'Gen 3',
        year: 2024,
        category: 'Motorcycle',
        fuelType: 'Petrol',
        bluetoothIdentifiers: ['KTM_MY_RIDE', '390_DUKE', 'KTM_BT_UNIT'],
        protocolAdapter: 'ktm_my_ride',
        supportedFunctions: ['read_speed', 'read_rpm', 'read_coolant_temp', 'read_gear', 'read_abs_mode', 'read_quickshifter_state'],
        model3DUrl: '',
        thumbnailUrl: 'assets/garage/thumbs/ktm_390duke.png',
        specifications: {
          engineCc: 398.7,
          powerBhp: 45.3,
          torqueNm: 39.0,
          curbWeightKg: 168,
          topSpeedKmh: 167,
          fuelCapacityL: 15.0,
          transmission: '6-speed with Slipper Clutch',
        },
        maintenanceIntervals: {
          oil_service: { km: 7500, months: 12, description: 'Motorex Cross Power 4T Oil & Filter' },
          valve_inspection: { km: 15000, months: 24, description: 'Valve Clearance Check' },
        }
      },

      // --- DIAGNOSTIC GATEWAY ---
      {
        manufacturer: 'Generic Gateway',
        model: 'OBD-II / CAN-Bus Adapter',
        variant: 'ELM327 / STN1110 BLE',
        year: 2024,
        category: 'Gateway',
        fuelType: 'Diagnostic Interface',
        bluetoothIdentifiers: ['OBDII', 'V-LINK', 'OBDLINK', 'CARISTA', 'VIEWEAR'],
        protocolAdapter: 'generic_obd2',
        supportedFunctions: ['read_speed', 'read_rpm', 'read_coolant_temp', 'read_battery_voltage', 'read_dtc_faults', 'clear_dtc_faults'],
        model3DUrl: '',
        thumbnailUrl: 'assets/garage/thumbs/generic_obd.png',
        specifications: {
          protocol: 'ISO 15765-4 (CAN), ISO 14230-4 (KWP2000), SAE J1850',
          voltageRange: '9.0V - 16.0V DC',
        },
        maintenanceIntervals: {}
      }
    ]);
  }

  getCatalogVersion() {
    return {
      version: '1.0.0',
      schemaVersion: '2.4.0',
      minimumSupportedModelYear: 2015,
      openFutureModelSupport: true,
      lastUpdated: new Date().toISOString(),
    };
  }

  async getManufacturers(): Promise<string[]> {
    const vehicles = await this.findAll();
    return Array.from(new Set(vehicles.map((v) => v.manufacturer))).sort();
  }

  async getCatalogTree(): Promise<Record<string, any[]>> {
    const vehicles = await this.findAll();
    const tree: Record<string, any[]> = {};

    for (const v of vehicles) {
      if (!tree[v.manufacturer]) {
        tree[v.manufacturer] = [];
      }
      tree[v.manufacturer].push({
        id: (v as any)._id || (v as any).id,
        model: v.model,
        variant: v.variant,
        year: v.year,
        category: v.category,
        fuelType: v.fuelType,
        protocolAdapter: v.protocolAdapter,
        supportedFunctions: v.supportedFunctions,
        specifications: v.specifications,
      });
    }

    return tree;
  }
}

