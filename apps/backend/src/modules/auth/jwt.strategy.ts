import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(configService: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.get<string>('JWT_SECRET', 'super_secret_rideos_jwt_key_2026'),
    });
  }

  async validate(payload: { sub: string; email: string }) {
    if (!payload.sub || !payload.email) {
      throw new UnauthorizedException('Invalid JWT payload');
    }
    return { userId: payload.sub, email: payload.email };
  }
}
