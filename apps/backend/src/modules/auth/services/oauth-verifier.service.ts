import { Injectable, Logger, UnauthorizedException, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';

export interface VerifiedOAuthUser {
  email: string;
  fullName?: string;
  sub: string;
  provider: 'google' | 'apple';
}

interface JwkKey {
  kty: string;
  kid: string;
  use?: string;
  alg?: string;
  n: string;
  e: string;
}

@Injectable()
export class OAuthVerifierService {
  private readonly logger = new Logger(OAuthVerifierService.name);

  // In-memory JWKS cache with TTL
  private googleJwksCache: { keys: JwkKey[]; fetchedAt: number } | null = null;
  private appleJwksCache: { keys: JwkKey[]; fetchedAt: number } | null = null;
  private readonly JWKS_CACHE_TTL_MS = 60 * 60 * 1000; // 1 hour

  constructor(private readonly configService: ConfigService) {}

  /**
   * Cryptographically verifies a Google OAuth ID Token using Google's public JWKS or TokenInfo endpoint
   */
  async verifyGoogleIdToken(idToken: string): Promise<VerifiedOAuthUser> {
    if (!idToken || typeof idToken !== 'string' || idToken.trim().length === 0) {
      throw new BadRequestException('Google ID token is required for OAuth authentication');
    }

    const trimmedToken = idToken.trim();

    // 1. Try cryptographic JWKS verification first
    try {
      const parts = trimmedToken.split('.');
      if (parts.length === 3) {
        const header = JSON.parse(Buffer.from(parts[0], 'base64url').toString('utf8'));
        const payload = JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf8'));

        // Verify standard claims
        const nowSec = Math.floor(Date.now() / 1000);
        if (payload.exp && payload.exp < nowSec) {
          throw new UnauthorizedException('Google ID token has expired');
        }

        const validIssuers = ['accounts.google.com', 'https://accounts.google.com'];
        if (!validIssuers.includes(payload.iss)) {
          throw new UnauthorizedException(`Invalid Google token issuer: ${payload.iss}`);
        }

        const configuredAudience =
          this.configService.get<string>('GOOGLE_CLIENT_ID') || process.env.GOOGLE_CLIENT_ID;
        if (configuredAudience && payload.aud !== configuredAudience) {
          throw new UnauthorizedException(`Google token audience mismatch: ${payload.aud}`);
        }

        // Fetch Google JWKS
        const jwks = await this.getGoogleJwks();
        const matchingKey = jwks.find((k) => k.kid === header.kid);

        if (matchingKey) {
          const isValid = this.verifyJwtSignature(parts[0], parts[1], parts[2], matchingKey);
          if (isValid) {
            if (!payload.email) {
              throw new UnauthorizedException('Google ID token payload does not contain an email claim');
            }
            return {
              email: payload.email.trim().toLowerCase(),
              fullName: payload.name || payload.given_name || null,
              sub: payload.sub,
              provider: 'google',
            };
          }
        }
      }
    } catch (err: any) {
      if (err instanceof UnauthorizedException) throw err;
      this.logger.warn(`[OAuth] Local JWKS verification failed for Google token (${err.message}). Falling back to Google TokenInfo.`);
    }

    // 2. Fallback to Google TokenInfo endpoint verification
    try {
      const url = `https://oauth2.googleapis.com/tokeninfo?id_token=${encodeURIComponent(trimmedToken)}`;
      const res = await fetch(url, {
        method: 'GET',
        headers: { Accept: 'application/json' },
        signal: AbortSignal.timeout(6000),
      });

      if (!res.ok) {
        throw new UnauthorizedException('Google token validation failed with Google OAuth servers');
      }

      const data = await res.json();
      if (!data.email) {
        throw new UnauthorizedException('Google token validation response is missing verified email');
      }

      const configuredAudience =
        this.configService.get<string>('GOOGLE_CLIENT_ID') || process.env.GOOGLE_CLIENT_ID;
      if (configuredAudience && data.aud !== configuredAudience) {
        throw new UnauthorizedException(`Google token audience mismatch: ${data.aud}`);
      }

      return {
        email: data.email.trim().toLowerCase(),
        fullName: data.name || data.given_name || null,
        sub: data.sub || data.user_id,
        provider: 'google',
      };
    } catch (err: any) {
      if (err instanceof UnauthorizedException) throw err;
      throw new UnauthorizedException(`Invalid or expired Google OAuth ID token: ${err.message}`);
    }
  }

  /**
   * Cryptographically verifies an Apple Sign-In Identity Token against Apple's public JWKS keys
   */
  async verifyAppleIdentityToken(identityToken: string): Promise<VerifiedOAuthUser> {
    if (!identityToken || typeof identityToken !== 'string' || identityToken.trim().length === 0) {
      throw new BadRequestException('Apple identity token is required for OAuth authentication');
    }

    const trimmedToken = identityToken.trim();
    const parts = trimmedToken.split('.');
    if (parts.length !== 3) {
      throw new BadRequestException('Malformed Apple identity token JWT');
    }

    let header: any;
    let payload: any;
    try {
      header = JSON.parse(Buffer.from(parts[0], 'base64url').toString('utf8'));
      payload = JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf8'));
    } catch {
      throw new BadRequestException('Invalid Base64URL encoding in Apple identity token');
    }

    // 1. Verify claims
    const nowSec = Math.floor(Date.now() / 1000);
    if (payload.exp && payload.exp < nowSec) {
      throw new UnauthorizedException('Apple identity token has expired');
    }

    if (payload.iss !== 'https://appleid.apple.com') {
      throw new UnauthorizedException(`Invalid Apple identity token issuer: ${payload.iss}`);
    }

    const configuredAudience =
      this.configService.get<string>('APPLE_CLIENT_ID') || process.env.APPLE_CLIENT_ID;
    if (configuredAudience && payload.aud !== configuredAudience) {
      throw new UnauthorizedException(`Apple token audience mismatch: ${payload.aud}`);
    }

    // 2. Verify signature with Apple JWKS
    try {
      const appleJwks = await this.getAppleJwks();
      const matchingKey = appleJwks.find((k) => k.kid === header.kid);

      if (!matchingKey) {
        throw new UnauthorizedException(`Apple signing key (kid: ${header.kid}) not found in Apple JWKS`);
      }

      const isValid = this.verifyJwtSignature(parts[0], parts[1], parts[2], matchingKey);
      if (!isValid) {
        throw new UnauthorizedException('Cryptographic signature verification failed for Apple token');
      }
    } catch (err: any) {
      if (err instanceof UnauthorizedException) throw err;
      this.logger.warn(`[OAuth] Apple JWKS verification error: ${err.message}`);
      throw new UnauthorizedException(`Apple token verification failed: ${err.message}`);
    }

    const email = payload.email
      ? payload.email.trim().toLowerCase()
      : `apple_${payload.sub.slice(0, 10)}@privaterelay.appleid.com`;

    return {
      email,
      fullName: payload.name || payload.given_name || null,
      sub: payload.sub,
      provider: 'apple',
    };
  }

  /**
   * Cryptographically verifies RS256 signature using Node.js crypto and JWK public key
   */
  private verifyJwtSignature(
    headerB64: string,
    payloadB64: string,
    signatureB64: string,
    jwk: JwkKey,
  ): boolean {
    try {
      const verifier = crypto.createVerify('RSA-SHA256');
      verifier.update(`${headerB64}.${payloadB64}`);

      const publicKey = crypto.createPublicKey({
        key: {
          kty: 'RSA',
          n: jwk.n,
          e: jwk.e,
        },
        format: 'jwk',
      });

      const signature = Buffer.from(signatureB64, 'base64url');
      return verifier.verify(publicKey, signature);
    } catch (err: any) {
      this.logger.error(`[OAuth] Signature verification failed: ${err.message}`);
      return false;
    }
  }

  private async getGoogleJwks(): Promise<JwkKey[]> {
    const now = Date.now();
    if (this.googleJwksCache && now - this.googleJwksCache.fetchedAt < this.JWKS_CACHE_TTL_MS) {
      return this.googleJwksCache.keys;
    }

    try {
      const res = await fetch('https://www.googleapis.com/oauth2/v3/certs', {
        headers: { Accept: 'application/json' },
        signal: AbortSignal.timeout(5000),
      });
      if (res.ok) {
        const data = await res.json();
        if (Array.isArray(data.keys)) {
          this.googleJwksCache = { keys: data.keys, fetchedAt: now };
          return data.keys;
        }
      }
    } catch (err: any) {
      this.logger.warn(`[OAuth] Failed to fetch Google JWKS: ${err.message}`);
    }

    return this.googleJwksCache?.keys || [];
  }

  private async getAppleJwks(): Promise<JwkKey[]> {
    const now = Date.now();
    if (this.appleJwksCache && now - this.appleJwksCache.fetchedAt < this.JWKS_CACHE_TTL_MS) {
      return this.appleJwksCache.keys;
    }

    try {
      const res = await fetch('https://appleid.apple.com/auth/keys', {
        headers: { Accept: 'application/json' },
        signal: AbortSignal.timeout(5000),
      });
      if (res.ok) {
        const data = await res.json();
        if (Array.isArray(data.keys)) {
          this.appleJwksCache = { keys: data.keys, fetchedAt: now };
          return data.keys;
        }
      }
    } catch (err: any) {
      this.logger.warn(`[OAuth] Failed to fetch Apple JWKS: ${err.message}`);
    }

    return this.appleJwksCache?.keys || [];
  }
}
