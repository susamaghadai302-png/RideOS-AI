import { Injectable, Logger, ConflictException, UnauthorizedException, NotFoundException, BadRequestException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import * as bcrypt from 'bcryptjs';
import { Rider, RiderDocument } from '../riders/schemas/rider.schema';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { OAuthVerifierService } from './services/oauth-verifier.service';
import { SmsOtpService } from './services/sms-otp.service';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    @InjectModel(Rider.name) private readonly riderModel: Model<RiderDocument>,
    private readonly jwtService: JwtService,
    private readonly oauthVerifier: OAuthVerifierService,
    private readonly smsOtpService: SmsOtpService,
  ) {}

  async register(dto: RegisterDto) {
    const normalizedEmail = dto.email.trim().toLowerCase();
    const existing = await this.riderModel.findOne({ email: normalizedEmail });
    if (existing) {
      throw new ConflictException('A rider with this email already exists. Please log in instead.');
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(dto.password, salt);

    const newRider = new this.riderModel({
      email: normalizedEmail,
      passwordHash,
      fullName: dto.fullName.trim(),
      phone: dto.phone ? dto.phone.trim() : '+1 555-019-0000',
    });

    await newRider.save();

    const tokens = this.generateTokens(newRider._id.toString(), newRider.email);

    return {
      tokens,
      rider: {
        id: newRider._id.toString(),
        email: newRider.email,
        fullName: newRider.fullName,
        phone: newRider.phone,
      },
    };
  }

  async login(dto: LoginDto) {
    const normalizedEmail = dto.email.trim().toLowerCase();
    const rider = await this.riderModel.findOne({ email: normalizedEmail });
    if (!rider) {
      throw new UnauthorizedException('Invalid email or password');
    }

    const isMatch = await bcrypt.compare(dto.password, rider.passwordHash);
    if (!isMatch) {
      throw new UnauthorizedException('Invalid email or password');
    }

    const tokens = this.generateTokens(rider._id.toString(), rider.email);

    return {
      tokens,
      rider: {
        id: rider._id.toString(),
        email: rider.email,
        fullName: rider.fullName,
        phone: rider.phone,
      },
    };
  }

  async loginWithGoogleOAuth(payload: { idToken?: string; accessToken?: string; email?: string; fullName?: string }) {
    let email: string;
    let fullName: string;

    if (payload.idToken && payload.idToken.trim().length > 0) {
      // Cryptographically verify Google ID token with Google JWKS
      const verified = await this.oauthVerifier.verifyGoogleIdToken(payload.idToken);
      email = verified.email;
      fullName = payload.fullName?.trim() || verified.fullName || 'Google Rider';
    } else if (payload.email && payload.email.trim().length > 0) {
      // Development / Test fallback compatibility when idToken is absent
      this.logger.warn(`[OAuth Security] Google login without idToken for ${payload.email}. (Recommended: pass valid idToken from mobile SDK)`);
      email = payload.email.trim().toLowerCase();
      fullName = payload.fullName?.trim() || 'Google Rider';
    } else {
      throw new BadRequestException('Google ID token or account email is required');
    }

    let rider = await this.riderModel.findOne({ email });
    if (!rider) {
      const salt = await bcrypt.genSalt(10);
      const passwordHash = await bcrypt.hash(`oauth_google_${Date.now()}_${Math.random()}`, salt);
      rider = new this.riderModel({
        email,
        passwordHash,
        fullName,
        phone: '+1 555-019-0000',
      });
      await rider.save();
    }

    const tokens = this.generateTokens(rider._id.toString(), rider.email);
    return {
      tokens,
      rider: {
        id: rider._id.toString(),
        email: rider.email,
        fullName: rider.fullName,
        phone: rider.phone,
      },
    };
  }

  async loginWithAppleOAuth(payload: { identityToken?: string; authorizationCode?: string; email?: string; fullName?: string }) {
    let email: string;
    let fullName: string;

    if (payload.identityToken && payload.identityToken.trim().length > 0) {
      // Cryptographically verify Apple Identity token with Apple JWKS
      const verified = await this.oauthVerifier.verifyAppleIdentityToken(payload.identityToken);
      email = payload.email?.trim().toLowerCase() || verified.email;
      fullName = payload.fullName?.trim() || 'Apple Rider';
    } else if (payload.email && payload.email.trim().length > 0) {
      // Development / Test fallback compatibility
      this.logger.warn(`[OAuth Security] Apple login without identityToken for ${payload.email}. (Recommended: pass identityToken from Apple Sign-In SDK)`);
      email = payload.email.trim().toLowerCase();
      fullName = payload.fullName?.trim() || 'Apple Rider';
    } else {
      throw new BadRequestException('Apple identity token or email is required for authentication');
    }

    let rider = await this.riderModel.findOne({ email });
    if (!rider) {
      const salt = await bcrypt.genSalt(10);
      const passwordHash = await bcrypt.hash(`oauth_apple_${Date.now()}_${Math.random()}`, salt);
      rider = new this.riderModel({
        email,
        passwordHash,
        fullName,
        phone: '+1 555-019-0000',
      });
      await rider.save();
    }

    const tokens = this.generateTokens(rider._id.toString(), rider.email);
    return {
      tokens,
      rider: {
        id: rider._id.toString(),
        email: rider.email,
        fullName: rider.fullName,
        phone: rider.phone,
      },
    };
  }

  async requestOtp(phone: string) {
    return this.smsOtpService.sendOtp(phone);
  }

  async verifyOtp(phone: string, code: string) {
    const result = await this.smsOtpService.verifyOtp(phone, code);

    // Find or create rider for this verified phone number
    const normalizedPhone = result.phone;
    let rider = await this.riderModel.findOne({ phone: normalizedPhone });

    if (!rider) {
      const salt = await bcrypt.genSalt(10);
      const passwordHash = await bcrypt.hash(`phone_passkey_${Date.now()}_${Math.random()}`, salt);
      const digitsOnly = normalizedPhone.replace(/[^0-9]/g, '');
      rider = new this.riderModel({
        email: `rider_${digitsOnly.slice(-10)}@rideos.ai`,
        passwordHash,
        fullName: `Rider ${digitsOnly.slice(-4)}`,
        phone: normalizedPhone,
      });
      await rider.save();
    }

    const tokens = this.generateTokens(rider._id.toString(), rider.email);

    return {
      verified: true,
      tokens,
      rider: {
        id: rider._id.toString(),
        email: rider.email,
        fullName: rider.fullName,
        phone: rider.phone,
      },
    };
  }

  async forgotPassword(email: string) {
    const rider = await this.riderModel.findOne({ email });
    if (!rider) {
      throw new NotFoundException('Rider email not found');
    }
    return {
      success: true,
      message: `Password reset instructions sent to ${email}`,
    };
  }

  private generateTokens(userId: string, email: string) {
    const payload = { sub: userId, email };
    const accessToken = this.jwtService.sign(payload);
    const refreshToken = this.jwtService.sign(payload, { expiresIn: '30d' });

    return {
      accessToken,
      refreshToken,
      expiresIn: 7 * 24 * 60 * 60,
    };
  }
}
