import { Injectable, NotFoundException } from '@nestjs/common';
import { ReconstructDigitalTwinDto, SaveDigitalTwinDto } from './dto/digital_twin.dto';

@Injectable()
export class DigitalTwinService {
  private inMemoryTwins: Map<string, any> = new Map();

  constructor() {
    // Pre-seed default system digital twins
    this.inMemoryTwins.set('vt_mt09sp_system', {
      twinId: 'vt_mt09sp_system',
      vehicleId: 'v_yamaha_mt09_sp',
      manufacturer: 'Yamaha',
      model: 'MT-09 SP',
      year: 2024,
      modelGlbPath: '',
      thumbnailUrl: 'assets/garage/yamaha_mt09_sp.png',
      quality: 'HIGH',
      scanCoveragePercent: 100.0,
      scanDate: new Date().toISOString(),
      sourceImageCount: 32,
      meshStats: { polygonCount: 124000, vertexCount: 81000, lengthMeters: 2.07, widthMeters: 0.81, heightMeters: 1.17, isGroundAligned: true },
      sourcePhotosPurged: false,
    });
  }

  async reconstruct(dto: ReconstructDigitalTwinDto) {
    const twinId = `vt_${Date.now().toString(16)}`;
    const isScooter = (dto.category || '').toLowerCase().includes('scooter') || dto.model.toLowerCase().includes('scooter') || dto.model.toLowerCase().includes('activa') || dto.model.toLowerCase().includes('burgman');

    const lowerModel = (dto.model || '').toLowerCase();
    const lowerMake = (dto.manufacturer || '').toLowerCase();

    let modelGlbPath = '';
    let thumbnailUrl = 'assets/garage/generic_obd.png';

    if (lowerModel.includes('panigale') || lowerMake.includes('ducati')) {
      modelGlbPath = 'assets/models/ducati_panigale.glb';
      thumbnailUrl = 'assets/garage/ducati_panigale.png';
    } else if (lowerModel.includes('m 1000') || lowerModel.includes('m1000') || (lowerMake.includes('bmw') && lowerModel.includes('1000'))) {
      modelGlbPath = 'assets/models/bmw_m1000rr.glb';
      thumbnailUrl = 'assets/garage/bmw_m1000rr.png';
    } else if (lowerModel.includes('r1m') || lowerModel.includes('r1') || (lowerMake.includes('yamaha') && lowerModel.includes('r1'))) {
      modelGlbPath = '';
      thumbnailUrl = 'assets/garage/yamaha_r1m.png';
    } else if (lowerModel.includes('mt') || lowerMake.includes('yamaha')) {
      modelGlbPath = '';
      thumbnailUrl = 'assets/garage/yamaha_mt09_sp.png';
    } else if (isScooter) {
      modelGlbPath = '';
      thumbnailUrl = 'assets/garage/suzuki_burgman.png';
    }

    const result = {
      twinId,
      vehicleId: dto.vehicleId,
      manufacturer: dto.manufacturer,
      model: dto.model,
      variant: dto.variant || 'Digital Twin',
      year: dto.year,
      category: dto.category || (isScooter ? 'Scooter' : 'Motorcycle'),
      modelGlbPath,
      thumbnailUrl,
      quality: dto.targetQuality || 'HIGH',
      scanCoveragePercent: 100.0,
      scanDate: new Date().toISOString(),
      sourceImageCount: dto.frameCount || 18,
      meshStats: {
        polygonCount: dto.targetQuality === 'ULTRA' ? 350000 : 120000,
        vertexCount: dto.targetQuality === 'ULTRA' ? 220000 : 78000,
        lengthMeters: isScooter ? 1.88 : 2.07,
        widthMeters: isScooter ? 0.71 : 0.81,
        heightMeters: isScooter ? 1.14 : 1.17,
        isGroundAligned: true,
      },
      componentHotspots: [
        { name: 'Front Brake & Caliper', pos: [0.0, 0.35, 0.75] },
        { name: 'Powertrain Core', pos: [0.0, 0.45, 0.0] },
        { name: 'Cockpit & Controls', pos: [0.0, 1.05, 0.45] },
      ],
      sourcePhotosPurged: false,
    };

    this.inMemoryTwins.set(twinId, result);
    this.inMemoryTwins.set(dto.vehicleId, result);
    return result;
  }

  async save(dto: SaveDigitalTwinDto) {
    this.inMemoryTwins.set(dto.twinId, dto);
    this.inMemoryTwins.set(dto.vehicleId, dto);
    return { success: true, twinId: dto.twinId };
  }

  async getById(id: string) {
    const twin = this.inMemoryTwins.get(id);
    if (!twin) {
      throw new NotFoundException(`Digital Twin ${id} not found`);
    }
    return twin;
  }

  async delete(id: string) {
    const twin = this.inMemoryTwins.get(id);
    if (twin) {
      this.inMemoryTwins.delete(twin.twinId);
      this.inMemoryTwins.delete(twin.vehicleId);
      return { success: true, deletedId: id };
    }
    throw new NotFoundException(`Digital Twin ${id} not found`);
  }

  async purgePhotos(twinId: string) {
    const twin = this.inMemoryTwins.get(twinId);
    if (twin) {
      twin.sourcePhotosPurged = true;
      twin.sourceImageCount = 0;
      return { success: true, twinId, message: 'Source photos purged securely' };
    }
    throw new NotFoundException(`Digital Twin ${twinId} not found`);
  }
}
