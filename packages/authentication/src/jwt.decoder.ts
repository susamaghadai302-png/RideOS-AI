export interface JwtPayload {
  sub: string;
  email: string;
  exp?: number;
  iat?: number;
}

export class JwtDecoder {
  /**
   * Decodes a JWT payload without external library dependencies
   */
  public static decode(token: string): JwtPayload | null {
    try {
      const parts = token.split('.');
      if (parts.length !== 3) return null;
      const base64Url = parts[1];
      // Normalize base64url → standard base64, then decode via Node Buffer
      const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
      const jsonPayload = Buffer.from(base64, 'base64').toString('utf-8');
      return JSON.parse(jsonPayload) as JwtPayload;
    } catch {
      return null;
    }
  }

  public static isExpired(token: string): boolean {
    const payload = this.decode(token);
    if (!payload || !payload.exp) return true;
    const nowInSeconds = Math.floor(Date.now() / 1000);
    return payload.exp <= nowInSeconds;
  }
}
