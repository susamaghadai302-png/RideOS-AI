import { Controller, Post, Delete, Body, HttpCode, HttpStatus } from '@nestjs/common';
import { PushNotificationsService } from './push-notifications.service';
import { NotificationCategory } from '@rideos/notifications';

@Controller('push-notifications')
export class PushNotificationsController {
  constructor(private readonly pushService: PushNotificationsService) {}

  @Post('token')
  @HttpCode(HttpStatus.OK)
  async registerToken(
    @Body('riderId') riderId: string,
    @Body('token') token: string,
    @Body('platform') platform: 'android' | 'ios' | 'web' = 'android',
  ) {
    return this.pushService.registerDeviceToken(riderId, token, platform);
  }

  @Delete('token')
  @HttpCode(HttpStatus.OK)
  async unregisterToken(
    @Body('riderId') riderId: string,
    @Body('token') token: string,
  ) {
    const success = await this.pushService.unregisterDeviceToken(riderId, token);
    return { success };
  }

  @Post('send')
  @HttpCode(HttpStatus.OK)
  async send(
    @Body('riderId') riderId: string,
    @Body('category') category: NotificationCategory,
    @Body('title') title: string,
    @Body('body') body: string,
    @Body('deepLinkUrl') deepLinkUrl?: string,
  ) {
    return this.pushService.sendNotification(riderId, category, title, body, deepLinkUrl);
  }

  @Post('alert/sos')
  @HttpCode(HttpStatus.OK)
  async sendSosAlert(
    @Body('riderId') riderId: string,
    @Body('incidentType') incidentType: string,
    @Body('locationText') locationText: string,
    @Body('lat') lat: number,
    @Body('lng') lng: number,
  ) {
    return this.pushService.sendEmergencySosAlert(riderId, { incidentType, locationText, lat, lng });
  }

  @Post('alert/theft')
  @HttpCode(HttpStatus.OK)
  async sendTheftAlert(
    @Body('riderId') riderId: string,
    @Body('vehicleName') vehicleName: string,
    @Body('alertReason') alertReason: string,
  ) {
    return this.pushService.sendTheftAlert(riderId, { name: vehicleName, alertReason });
  }
}

