import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { PushNotificationsService } from './push-notifications.service';

describe('PushNotificationsService', () => {
  let service: PushNotificationsService;

  const mockConfigService = {
    get: jest.fn().mockReturnValue(undefined),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PushNotificationsService,
        {
          provide: ConfigService,
          useValue: mockConfigService,
        },
      ],
    }).compile();

    service = module.get<PushNotificationsService>(PushNotificationsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should register and unregister device FCM push tokens', async () => {
    const riderId = 'rider-fcm-001';
    const token = 'fcm-device-token-xyz-123';

    // 1. Register Token
    const regResult = await service.registerDeviceToken(riderId, token, 'android');
    expect(regResult.success).toBe(true);
    expect(service.getDeviceTokens(riderId)).toContain(token);

    // 2. Unregister Token
    const unregResult = await service.unregisterDeviceToken(riderId, token);
    expect(unregResult).toBe(true);
    expect(service.getDeviceTokens(riderId)).not.toContain(token);
  });

  it('should dispatch high priority Emergency SOS notification with deep link', async () => {
    const riderId = 'rider-fcm-002';
    await service.registerDeviceToken(riderId, 'fcm-test-token-sos', 'android');

    const result = await service.sendEmergencySosAlert(riderId, {
      incidentType: 'Severe Fall Impact',
      locationText: 'Skyline Boulevard Mile 14',
      lat: 37.3861,
      lng: -122.0839,
    });

    expect(result).toBeDefined();
    expect(result.category).toBe('EMERGENCY_SOS');
    expect(result.deepLinkUrl).toContain('rideos://sos');
    expect(result.recipientRiderId).toBe(riderId);
  });

  it('should dispatch crash alert notification', async () => {
    const riderId = 'rider-fcm-003';
    const result = await service.sendCrashAlert(riderId, {
      gForce: 4.8,
      location: 'Highway 9 Northbound',
    });

    expect(result.category).toBe('CRASH_DETECTED');
    expect(result.title).toContain('HIGH G-FORCE');
  });

  it('should dispatch theft geofence notification', async () => {
    const riderId = 'rider-fcm-004';
    const result = await service.sendTheftAlert(riderId, {
      name: 'Ducati Panigale V4',
      alertReason: 'Movement without key ignition in garage perimeter',
    });

    expect(result.category).toBe('THEFT_GEOFENCE');
    expect(result.title).toContain('Ducati Panigale V4');
    expect(result.body).toContain('Movement without key ignition');
  });
});
