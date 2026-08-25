import { JwtDecoder, JwtPayload } from './jwt.decoder';

export class AuthTokenManager {
  private accessToken: string | null = null;
  private refreshToken: string | null = null;

  public setTokens(accessToken: string, refreshToken: string): void {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  public getAccessToken(): string | null {
    if (this.accessToken && JwtDecoder.isExpired(this.accessToken)) {
      return null;
    }
    return this.accessToken;
  }

  public getRefreshToken(): string | null {
    return this.refreshToken;
  }

  public clearTokens(): void {
    this.accessToken = null;
    this.refreshToken = null;
  }

  public getUserPayload(): JwtPayload | null {
    if (!this.accessToken) return null;
    return JwtDecoder.decode(this.accessToken);
  }
}
