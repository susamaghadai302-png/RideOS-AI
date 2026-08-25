import { Test, TestingModule } from '@nestjs/testing';
import { DigitalTwinService } from './digital_twin.service';
import { NotFoundException } from '@nestjs/common';

describe('DigitalTwinService', () => {
  let service: DigitalTwinService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [DigitalTwinService],
    }).compile();

    service = module.get<DigitalTwinService>(DigitalTwinService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should retrieve pre-seeded digital twin for Yamaha MT-09 SP', async () => {
    const twin = await service.getById('vt_mt09sp_system');
    expect(twin).toBeDefined();
    expect(twin.manufacturer).toBe('Yamaha');
    expect(twin.model).toBe('MT-09 SP');
    expect(twin.modelGlbPath).toBe('');
  });

  it('should reconstruct a dedicated digital twin for custom scooter without sportbike substitution', async () => {
    const customScooter = await service.reconstruct({
      vehicleId: 'v_custom_activa_99',
      manufacturer: 'Honda',
      model: 'Activa 6G',
      category: 'Scooter',
      year: 2024,
      targetQuality: 'HIGH',
      frameCount: 24,
    });

    expect(customScooter.twinId).toBeDefined();
    expect(customScooter.category).toBe('Scooter');
    expect(customScooter.modelGlbPath).toBe(''); // Pending authentic OEM scan, zero fake bike
  });

  it('should enforce vehicle isolation and avoid cross-vehicle model contamination', async () => {
    const vehicleA = await service.reconstruct({
      vehicleId: 'v_aprilia_rs660',
      manufacturer: 'Aprilia',
      model: 'RS 660',
      category: 'Sportbike',
      year: 2024,
      targetQuality: 'ULTRA',
      frameCount: 32,
    });

    const retrievedA = await service.getById(vehicleA.twinId);
    expect(retrievedA.vehicleId).toBe('v_aprilia_rs660');

    await expect(service.getById('non_existent_id')).rejects.toThrow(NotFoundException);
  });

  it('should purge source photos securely for privacy', async () => {
    const twin = await service.reconstruct({
      vehicleId: 'v_privacy_test_bike',
      manufacturer: 'KTM',
      model: 'Duke 390',
      category: 'Naked',
      year: 2024,
      frameCount: 18,
    });

    const purgeRes = await service.purgePhotos(twin.twinId);
    expect(purgeRes.success).toBe(true);

    const updated = await service.getById(twin.twinId);
    expect(updated.sourcePhotosPurged).toBe(true);
    expect(updated.sourceImageCount).toBe(0);
  });
});
