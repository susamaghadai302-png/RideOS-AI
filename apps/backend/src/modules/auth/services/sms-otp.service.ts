import { Injectable, Logger, UnauthorizedException, BadRequestException, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';

interface OtpRecord {
  code: string;
  expiresAt: number;
  attempts: number;
  otpRef: string;
}

@Injectable()
export class SmsOtpService {
  private readonly logger = new Logger(SmsOtpService.name);
  private readonly otpStore = new Map<string, OtpRecord>();
  private readonly OTP_TTL_MS = 5 * 60 * 1000; // 5 minutes
  private readonly MAX_ATTEMPTS = 3;

  constructor(private readonly configService: ConfigService) {}

  /**
   * Generates a cryptographically secure 6-digit OTP and delivers it via Twilio SMS or secure logger
   */
  async sendOtp(phone: string): Promise<{ success: boolean; message: string; otpRef: string }> {
    const normalizedPhone = this.normalizePhoneNumber(phone);
    if (!normalizedPhone || normalizedPhone.length < 8) {
      throw new BadRequestException('Please provide a valid phone number with country code');
    }

    const code = crypto.randomInt(100000, 999999).toString();
    const otpRef = `RIDEOS-OTP-${crypto.randomBytes(3).toString('hex').toUpperCase()}`;

    this.otpStore.set(normalizedPhone, {
      code,
      expiresAt: Date.now() + this.OTP_TTL_MS,
      attempts: 0,
      otpRef,
    });

    const accountSid = this.configService.get<string>('TWILIO_ACCOUNT_SID') || process.env.TWILIO_ACCOUNT_SID;
    const authToken = this.configService.get<string>('TWILIO_AUTH_TOKEN') || process.env.TWILIO_AUTH_TOKEN;
    const fromPhone = this.configService.get<string>('TWILIO_FROM_PHONE') || process.env.TWILIO_FROM_PHONE;

    if (accountSid && authToken && fromPhone) {
      try {
        const url = `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`;
        const bodyParams = new URLSearchParams({
          To: normalizedPhone,
          From: fromPhone,
          Body: `Your RideOS AI verification code is ${code}. Valid for 5 minutes. Do not share. Ref: ${otpRef}`,
        });

        const authHeader = `Basic ${Buffer.from(`${accountSid}:${authToken}`).toString('base64')}`;
        const response = await fetch(url, {
          method: 'POST',
          headers: {
            Authorization: authHeader,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: bodyParams.toString(),
          signal: AbortSignal.timeout(8000),
        });

        if (!response.ok) {
          this.otpStore.delete(normalizedPhone);
          this.logger.error(
            `[Twilio SMS] Delivery failed with HTTP ${response.status}.`,
          );
          throw new ServiceUnavailableException(
            'SMS delivery failed. Please try again later.',
          );
        }

        this.logger.log(
          `[Twilio SMS] Successfully delivered verification OTP (Ref: ${otpRef})`,
        );
      } catch (err: unknown) {
        this.otpStore.delete(normalizedPhone);
        if (err instanceof ServiceUnavailableException) {
          throw err;
        }

        this.logger.error(
          `[Twilio SMS] Request failed (${err instanceof Error ? err.name : 'UnknownError'}).`,
        );
        throw new ServiceUnavailableException(
          'SMS delivery failed. Please try again later.',
        );
      }
    } else {
      const environment = this.configService.get<string>('NODE_ENV') || process.env.NODE_ENV || 'development';
      if (environment === 'production') {
        this.otpStore.delete(normalizedPhone);
        throw new ServiceUnavailableException('SMS delivery is not configured for production.');
      }
      this.logger.log(
        `[SmsOtpService] [DEV/LOCAL AUTH] OTP generated for ${normalizedPhone} (Ref: ${otpRef})`,
      );
    }

    return {
      success: true,
      message: `Verification code sent to ${normalizedPhone}`,
      otpRef,
    };
  }

  /**
   * Verifies an OTP code against stored records with attempt limiting and expiration checks
   */
  async verifyOtp(phone: string, code: string): Promise<{ verified: boolean; phone: string }> {
    const normalizedPhone = this.normalizePhoneNumber(phone);
    if (!normalizedPhone || !code || code.trim().length === 0) {
      throw new BadRequestException('Phone number and 6-digit verification code are required');
    }

    const cleanCode = code.trim();
    const record = this.otpStore.get(normalizedPhone);

    if (!record || Date.now() > record.expiresAt) {
      this.otpStore.delete(normalizedPhone);
      throw new UnauthorizedException('Verification code has expired. Please request a new OTP.');
    }

    if (record.attempts >= this.MAX_ATTEMPTS) {
      this.otpStore.delete(normalizedPhone);
      throw new UnauthorizedException('Too many failed attempts. This OTP has been invalidated. Please request a new one.');
    }

    if (record.code !== cleanCode) {
      record.attempts++;
      const remaining = this.MAX_ATTEMPTS - record.attempts;
      throw new UnauthorizedException(
        remaining > 0
          ? `Invalid verification code. ${remaining} attempt(s) remaining.`
          : 'Invalid verification code. Maximum attempts exceeded.',
      );
    }

    // Successfully verified -> consume one-time passkey
    this.otpStore.delete(normalizedPhone);
    return {
      verified: true,
      phone: normalizedPhone,
    };
  }

  private normalizePhoneNumber(phone: string): string {
    if (!phone) return '';
    return phone.replace(/[\s\-()]/g, '');
  }
}
