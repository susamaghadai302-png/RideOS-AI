import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NotificationPayload, NotificationCategory } from '@rideos/notifications';
import { randomUUID } from 'crypto';

export interface DeviceTokenInfo {
  token: string;
  platform: 'android' | 'ios' | 'web';
  registeredAt: string;
  lastActiveAt: string;
}

@Injectable()
export class PushNotificationsService {
  private readonly logger = new Logger(PushNotificationsService.name);

  // In-memory / cache device token store mapped by riderId -> List of tokens
  private readonly riderTokenStore = new Map<string, Map<string, DeviceTokenInfo>>();

  constructor(private readonly configService: ConfigService) {}

  /**
   * Registers a client device FCM push token for a rider
   */
  async registerDeviceToken(
    riderId: string,
    token: string,
    platform: 'android' | 'ios' | 'web' = 'android',
  ): Promise<{ success: boolean; token: string }> {
    if (!riderId || !token) {
      return { success: false, token };
    }

    if (!this.riderTokenStore.has(riderId)) {
      this.riderTokenStore.set(riderId, new Map());
    }

    const riderTokens = this.riderTokenStore.get(riderId)!;
    riderTokens.set(token, {
      token,
      platform,
      registeredAt: new Date().toISOString(),
      lastActiveAt: new Date().toISOString(),
    });

    this.logger.log(`[Push Notification] Registered ${platform} FCM token for rider ${riderId} (Total tokens: ${riderTokens.size})`);
    return { success: true, token };
  }

  /**
   * Unregisters a client device FCM token (e.g. on logout)
   */
  async unregisterDeviceToken(riderId: string, token: string): Promise<boolean> {
    const riderTokens = this.riderTokenStore.get(riderId);
    if (riderTokens && riderTokens.has(token)) {
      riderTokens.delete(token);
      return true;
    }
    return false;
  }

  /**
   * Retrieves all registered device tokens for a rider
   */
  getDeviceTokens(riderId: string): string[] {
    const riderTokens = this.riderTokenStore.get(riderId);
    if (!riderTokens) return [];
    return Array.from(riderTokens.keys());
  }

  /**
   * Dispatches a real Cloud Push Notification to a rider across all active devices
   */
  async sendNotification(
    recipientRiderId: string,
    category: NotificationCategory,
    title: string,
    body: string,
    deepLinkUrl?: string,
  ): Promise<NotificationPayload> {
    const payload: NotificationPayload = {
      id: `notif-${Date.now()}-${randomUUID().slice(0, 8)}`,
      recipientRiderId,
      category,
      title,
      body,
      deepLinkUrl,
      sentAt: new Date().toISOString(),
    };

    const tokens = this.getDeviceTokens(recipientRiderId);
    const channelId = this.resolveAndroidChannel(category);
    const priority = this.resolvePriority(category);

    this.logger.log(
      `[Push Dispatch] Sending ${category} (Channel: ${channelId}, Priority: ${priority}) to rider ${recipientRiderId} on ${tokens.length} device(s): "${title}"`,
    );

    // Attempt real delivery to each device token via FCM
    for (const token of tokens) {
      await this.dispatchFcmPush(token, payload, channelId, priority);
    }

    return payload;
  }

  /**
   * Sends high-priority SOS emergency alert notification
   */
  async sendEmergencySosAlert(
    riderId: string,
    emergency: { incidentType: string; locationText: string; lat: number; lng: number },
  ): Promise<NotificationPayload> {
    return this.sendNotification(
      riderId,
      'EMERGENCY_SOS',
      'CRITICAL: Emergency SOS Triggered',
      `${emergency.incidentType} detected near ${emergency.locationText}. Emergency services & contacts notified.`,
      `rideos://sos?lat=${emergency.lat}&lng=${emergency.lng}`,
    );
  }

  /**
   * Sends crash detection push alert
   */
  async sendCrashAlert(
    riderId: string,
    crashInfo: { gForce: number; location: string },
  ): Promise<NotificationPayload> {
    return this.sendNotification(
      riderId,
      'CRASH_DETECTED',
      'HIGH G-FORCE IMPACT DETECTED',
      `Impact of ${crashInfo.gForce.toFixed(1)}G detected near ${crashInfo.location}. Tap to verify rider safety or call emergency.`,
      'rideos://crash-response',
    );
  }

  /**
   * Sends vehicle theft / geofence alert
   */
  async sendTheftAlert(
    riderId: string,
    vehicle: { name: string; alertReason: string },
  ): Promise<NotificationPayload> {
    return this.sendNotification(
      riderId,
      'THEFT_GEOFENCE',
      `SECURITY ALERT: ${vehicle.name}`,
      `Unauthorized movement detected (${vehicle.alertReason}). Real-time GPS tracking active.`,
      'rideos://vehicle/security',
    );
  }

  /**
   * Sends TPMS low tire pressure alert
   */
  async sendTpmsAlert(
    riderId: string,
    tpms: { vehicleName: string; tire: 'Front' | 'Rear'; psi: number },
  ): Promise<NotificationPayload> {
    return this.sendNotification(
      riderId,
      'TPMS_WARNING',
      `TPMS Warning: ${tpms.tire} Tire Low`,
      `${tpms.vehicleName} ${tpms.tire} tire dropped to ${tpms.psi.toFixed(1)} PSI. Inflate before high-speed riding.`,
      'rideos://tpms',
    );
  }

  /**
   * Sends maintenance due reminder
   */
  async sendMaintenanceAlert(
    riderId: string,
    maint: { vehicleName: string; serviceTitle: string; remainingKm: number },
  ): Promise<NotificationPayload> {
    return this.sendNotification(
      riderId,
      'MAINTENANCE_DUE',
      `Service Due: ${maint.serviceTitle}`,
      `${maint.vehicleName} requires scheduled inspection in ${maint.remainingKm} km.`,
      'rideos://maintenance',
    );
  }

  private async dispatchFcmPush(
    token: string,
    payload: NotificationPayload,
    channelId: string,
    priority: 'high' | 'normal',
  ): Promise<void> {
    const serverKey =
      this.configService.get<string>('FIREBASE_SERVER_KEY') || process.env.FIREBASE_SERVER_KEY;
    const projectId =
      this.configService.get<string>('FIREBASE_PROJECT_ID') || process.env.FIREBASE_PROJECT_ID;

    if (serverKey) {
      try {
        const response = await fetch('https://fcm.googleapis.com/fcm/send', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `key=${serverKey}`,
          },
          body: JSON.stringify({
            to: token,
            priority,
            notification: {
              title: payload.title,
              body: payload.body,
              sound: 'default',
              android_channel_id: channelId,
            },
            data: {
              id: payload.id,
              category: payload.category,
              deepLinkUrl: payload.deepLinkUrl || '',
              sentAt: payload.sentAt,
            },
          }),
          signal: AbortSignal.timeout(6000),
        });

        if (response.ok) {
          this.logger.log(`[FCM Live Push] Delivered message to token ${token.slice(0, 10)}... (Status: ${response.status})`);
        } else {
          const errText = await response.text();
          this.logger.warn(`[FCM Live Push] Failed delivering to token ${token.slice(0, 10)}... (${response.status}): ${errText}`);
        }
      } catch (err: any) {
        this.logger.warn(`[FCM Live Push] Request error: ${err.message}`);
      }
    } else {
      this.logger.log(
        `[FCM Mock Delivery] [Simulated Firebase Push] To Token: ${token.slice(0, 10)}... | Channel: ${channelId} | Title: "${payload.title}"`,
      );
    }
  }

  private resolveAndroidChannel(category: NotificationCategory): string {
    switch (category) {
      case 'EMERGENCY_SOS':
      case 'CRASH_DETECTED':
        return 'rideos_critical_alerts';
      case 'THEFT_GEOFENCE':
      case 'TPMS_WARNING':
        return 'rideos_vehicle_health';
      case 'HAZARD_ALERT':
      case 'WEATHER_WARNING':
        return 'rideos_navigation';
      case 'MAINTENANCE_DUE':
      case 'SQUAD_INVITE':
      default:
        return 'rideos_general';
    }
  }

  private resolvePriority(category: NotificationCategory): 'high' | 'normal' {
    switch (category) {
      case 'EMERGENCY_SOS':
      case 'CRASH_DETECTED':
      case 'THEFT_GEOFENCE':
      case 'TPMS_WARNING':
      case 'HAZARD_ALERT':
        return 'high';
      default:
        return 'normal';
    }
  }
}
