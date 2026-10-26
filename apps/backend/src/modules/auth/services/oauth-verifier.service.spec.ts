import { UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OAuthVerifierService } from './oauth-verifier.service';

function token(
  payload: Record<string, unknown>,
  header: Record<string, unknown> = { alg: 'RS256', kid: 'test-key' },
): string {
  const encodedHeader = Buffer.from(JSON.stringify(header)).toString('base64url');
  const encodedPayload = Buffer.from(JSON.stringify(payload)).toString('base64url');
  return `${encodedHeader}.${encodedPayload}.signature`;
}

describe('OAuthVerifierService security boundaries', () => {
  const originalGoogleClientId = process.env.GOOGLE_CLIENT_ID;
  const originalAppleClientId = process.env.APPLE_CLIENT_ID;
  let googleClientId: string | undefined;
  let appleClientId: string | undefined;
  let service: OAuthVerifierService;

  beforeEach(() => {
    process.env.GOOGLE_CLIENT_ID = '';
    process.env.APPLE_CLIENT_ID = '';
    googleClientId = undefined;
    appleClientId = undefined;

    const configService = {
      get: jest.fn((key: string) => {
        if (key === 'GOOGLE_CLIENT_ID') return googleClientId;
        if (key === 'APPLE_CLIENT_ID') return appleClientId;
        return undefined;
      }),
    } as unknown as ConfigService;

    service = new OAuthVerifierService(configService);
  });

  afterAll(() => {
    if (originalGoogleClientId === undefined) {
      delete process.env.GOOGLE_CLIENT_ID;
    } else {
      process.env.GOOGLE_CLIENT_ID = originalGoogleClientId;
    }

    if (originalAppleClientId === undefined) {
      delete process.env.APPLE_CLIENT_ID;
    } else {
      process.env.APPLE_CLIENT_ID = originalAppleClientId;
    }
  });

  it('rejects Google tokens when the expected OAuth client ID is not configured', async () => {
    await expect(service.verifyGoogleIdToken('header.payload.signature'))
      .rejects.toThrow('Google OAuth client ID is not configured');
  });

  it('rejects Google tokens whose audience does not match the configured client', async () => {
    googleClientId = 'trusted-google-client';
    const jwt = token({
      exp: Math.floor(Date.now() / 1000) + 300,
      iss: 'https://accounts.google.com',
      aud: 'different-google-client',
      sub: 'google-subject',
      email: 'rider@example.com',
      email_verified: true,
    });

    await expect(service.verifyGoogleIdToken(jwt))
      .rejects.toThrow('Google token audience mismatch');
  });

  it('rejects Google tokens without a valid expiry', async () => {
    googleClientId = 'trusted-google-client';
    const jwt = token({
      iss: 'https://accounts.google.com',
      aud: 'trusted-google-client',
      sub: 'google-subject',
      email: 'rider@example.com',
      email_verified: true,
    });

    await expect(service.verifyGoogleIdToken(jwt))
      .rejects.toThrow('Google ID token is expired or missing an expiry');
  });

  it('rejects Apple tokens when the expected OAuth client ID is not configured', async () => {
    await expect(service.verifyAppleIdentityToken('header.payload.signature'))
      .rejects.toThrow('Apple OAuth client ID is not configured');
  });

  it('rejects Apple tokens whose audience does not match the configured client', async () => {
    appleClientId = 'trusted-apple-client';
    const jwt = token({
      exp: Math.floor(Date.now() / 1000) + 300,
      iss: 'https://appleid.apple.com',
      aud: 'different-apple-client',
      sub: 'apple-subject',
    });

    await expect(service.verifyAppleIdentityToken(jwt))
      .rejects.toThrow('Apple token audience mismatch');
  });

  it('rejects Apple tokens that supply an explicitly unverified email', async () => {
    appleClientId = 'trusted-apple-client';
    const jwt = token({
      exp: Math.floor(Date.now() / 1000) + 300,
      iss: 'https://appleid.apple.com',
      aud: 'trusted-apple-client',
      sub: 'apple-subject',
      email: 'unverified@example.com',
      email_verified: false,
    });

    await expect(service.verifyAppleIdentityToken(jwt))
      .rejects.toThrow(UnauthorizedException);
  });
});
