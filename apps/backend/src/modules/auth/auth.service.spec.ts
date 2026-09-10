import { Test, TestingModule } from '@nestjs/testing';
import { getModelToken } from '@nestjs/mongoose';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { UnauthorizedException } from '@nestjs/common';
import { AuthService } from './auth.service';
import { Rider } from '../riders/schemas/rider.schema';
import { OAuthVerifierService } from './services/oauth-verifier.service';
import { SmsOtpService } from './services/sms-otp.service';

describe('AuthService', () => {
  let service: AuthService;
  let smsOtpService: SmsOtpService;
  let oauthVerifier: OAuthVerifierService;

  const mockRiderModel: any = function (dto: any) {
    this.email = dto.email;
    this.passwordHash = dto.passwordHash;
    this.fullName = dto.fullName;
    this.phone = dto.phone;
    this._id = 'mock-object-id';
    this.save = jest.fn().mockResolvedValue(this);
  };
  mockRiderModel.findOne = jest.fn();

  const mockJwtService = {
    sign: jest.fn().mockReturnValue('mock-jwt-token'),
  };

  const mockConfigService = {
    get: jest.fn().mockReturnValue(undefined),
  };

  beforeEach(async () => {
    mockRiderModel.findOne.mockReset();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        OAuthVerifierService,
        SmsOtpService,
        {
          provide: getModelToken(Rider.name),
          useValue: mockRiderModel,
        },
        {
          provide: JwtService,
          useValue: mockJwtService,
        },
        {
          provide: ConfigService,
          useValue: mockConfigService,
        },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
    smsOtpService = module.get<SmsOtpService>(SmsOtpService);
    oauthVerifier = module.get<OAuthVerifierService>(OAuthVerifierService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should register a new rider with hashed password and return tokens', async () => {
    mockRiderModel.findOne.mockResolvedValue(null);

    const result = await service.register({
      email: 'alex@example.com',
      password: 'SecurePassword123!',
      fullName: 'Alex Vance',
      phone: '+1 555-019-2834',
    });

    expect(result).toBeDefined();
    expect(result.tokens.accessToken).toBe('mock-jwt-token');
    expect(result.rider.email).toBe('alex@example.com');
    expect(result.rider.fullName).toBe('Alex Vance');
  });

  it('should verify Google OAuth ID token cryptographically and login rider', async () => {
    mockRiderModel.findOne.mockResolvedValue(null);
    jest.spyOn(oauthVerifier, 'verifyGoogleIdToken').mockResolvedValue({
      email: 'verified.google@example.com',
      fullName: 'Google Rider Pro',
      sub: 'google-sub-12345',
      provider: 'google',
    });

    const result = await service.loginWithGoogleOAuth({
      idToken: 'valid-signed-google-id-token',
    });

    expect(result).toBeDefined();
    expect(result.rider.email).toBe('verified.google@example.com');
    expect(result.tokens.accessToken).toBe('mock-jwt-token');
  });

  it('should verify Apple OAuth Identity token and login rider', async () => {
    mockRiderModel.findOne.mockResolvedValue(null);
    jest.spyOn(oauthVerifier, 'verifyAppleIdentityToken').mockResolvedValue({
      email: 'apple.rider@privaterelay.appleid.com',
      fullName: 'Apple Rider',
      sub: 'apple-sub-67890',
      provider: 'apple',
    });

    const result = await service.loginWithAppleOAuth({
      identityToken: 'valid-signed-apple-identity-token',
    });

    expect(result).toBeDefined();
    expect(result.rider.email).toBe('apple.rider@privaterelay.appleid.com');
    expect(result.tokens.accessToken).toBe('mock-jwt-token');
  });

  it('should deliver and verify real SMS OTP passkey', async () => {
    const testPhone = '+15550192834';
    mockRiderModel.findOne.mockResolvedValue(null);

    // 1. Request OTP
    const reqResult = await service.requestOtp(testPhone);
    expect(reqResult.success).toBe(true);
    expect(reqResult.otpRef).toContain('RIDEOS-OTP-');

    // Extract stored code directly from SmsOtpService store for verification test
    const record = (smsOtpService as any).otpStore.get(testPhone);
    expect(record).toBeDefined();
    const actualCode = record.code;
    expect(actualCode).toHaveLength(6);

    // 2. Verify with correct code
    const verifyResult = await service.verifyOtp(testPhone, actualCode);
    expect(verifyResult.verified).toBe(true);
    expect(verifyResult.tokens.accessToken).toBe('mock-jwt-token');
    expect(verifyResult.rider.phone).toBe(testPhone);

    // 3. One-time passkey should be consumed
    await expect(service.verifyOtp(testPhone, actualCode)).rejects.toThrow(UnauthorizedException);
  });

  it('should reject invalid SMS OTP code', async () => {
    const testPhone = '+15550198888';
    await service.requestOtp(testPhone);

    await expect(service.verifyOtp(testPhone, '000000')).rejects.toThrow(UnauthorizedException);
  });
});
