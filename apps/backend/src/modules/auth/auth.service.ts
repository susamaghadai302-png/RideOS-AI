import { Injectable, Logger, ConflictException, UnauthorizedException, NotFoundException, BadRequestException, NotImplementedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import * as bcrypt from 'bcryptjs';
import { Rider, RiderDocument } from '../riders/schemas/rider.schema';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { OAuthVerifierService } from './services/oauth-verifier.service';
import { SmsOtpService } from './services/sms-otp.service';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    @InjectModel(Rider.name) private readonly riderModel: Model<RiderDocument>,
    private readonly jwtService: JwtService,
    private readonly oauthVerifier: OAuthVerifierService,
    private readonly smsOtpService: SmsOtpService,
    private readonly configService: ConfigService,
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
      phone: dto.phone?.trim(),
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
    if (!payload.idToken?.trim()) {
      throw new BadRequestException('Google ID token is required');
    }

    const verified = await this.oauthVerifier.verifyGoogleIdToken(payload.idToken);
    const email = verified.email.trim().toLowerCase();
    const fullName = payload.fullName?.trim() || verified.fullName || 'Unknown';

    let rider = await this.riderModel.findOne({ email });
    if (!rider) {
      const salt = await bcrypt.genSalt(10);
      const passwordHash = await bcrypt.hash(`oauth_google_${Date.now()}_${Math.random()}`, salt);
      rider = new this.riderModel({ email, passwordHash, fullName });
      await rider.save();
    }

    const tokens = this.generateTokens(rider._id.toString(), rider.email);
    return { tokens, rider: { id: rider._id.toString(), email: rider.email, fullName: rider.fullName, phone: rider.phone } };
  }
  async loginWithAppleOAuth(payload: { identityToken?: string; authorizationCode?: string; email?: string; fullName?: string }) {
    if (!payload.identityToken?.trim()) {
      throw new BadRequestException('Apple identity token is required');
    }

    const verified = await this.oauthVerifier.verifyAppleIdentityToken(payload.identityToken);
    // Identity email comes only from the cryptographically verified token; never trust client-supplied email.
    const email = verified.email.trim().toLowerCase();
    const fullName = payload.fullName?.trim() || verified.fullName || 'Unknown';

    let rider = await this.riderModel.findOne({ email });
    if (!rider) {
      const salt = await bcrypt.genSalt(10);
      const passwordHash = await bcrypt.hash(`oauth_apple_${Date.now()}_${Math.random()}`, salt);
      rider = new this.riderModel({ email, passwordHash, fullName });
      await rider.save();
    }

    const tokens = this.generateTokens(rider._id.toString(), rider.email);
    return { tokens, rider: { id: rider._id.toString(), email: rider.email, fullName: rider.fullName, phone: rider.phone } };
  }
  async refresh(refreshToken: string) {
    if (!refreshToken?.trim()) {
      throw new BadRequestException('Refresh token is required');
    }

    const refreshSecret =
      this.configService.get<string>('JWT_REFRESH_SECRET') ||
      this.configService.get<string>('JWT_SECRET') ||
      'super_secret_rideos_jwt_key_2026';

    try {
      const payload = this.jwtService.verify<{ sub: string; email: string; type?: string }>(
        refreshToken.trim(),
        { secret: refreshSecret },
      );
      if (payload.type !== 'refresh' || !payload.sub || !payload.email) {
        throw new UnauthorizedException('Invalid refresh token');
      }
      const rider = await this.riderModel.findOne({ _id: payload.sub });
      if (!rider) {
        throw new UnauthorizedException('Rider account no longer exists');
      }
      return this.generateTokens(rider._id.toString(), rider.email);
    } catch (error) {
      if (error instanceof UnauthorizedException) throw error;
      throw new UnauthorizedException('Invalid or expired refresh token');
    }
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
    throw new NotImplementedException('Email delivery is not currently configured.');
  }

  private generateTokens(userId: string, email: string) {
    const accessSecret = this.configService.get<string>('JWT_SECRET') || 'super_secret_rideos_jwt_key_2026';
    const refreshSecret = this.configService.get<string>('JWT_REFRESH_SECRET') || accessSecret;
    const accessExpiration = this.configService.get<string>('JWT_EXPIRATION') || '7d';
    const refreshExpiration = this.configService.get<string>('JWT_REFRESH_EXPIRATION') || '30d';

    const accessToken = this.jwtService.sign(
      { sub: userId, email, type: 'access' },
      { secret: accessSecret, expiresIn: accessExpiration },
    );
    const refreshToken = this.jwtService.sign(
      { sub: userId, email, type: 'refresh' },
      { secret: refreshSecret, expiresIn: refreshExpiration },
    );

    return { accessToken, refreshToken, expiresIn: 7 * 24 * 60 * 60 };
  }}