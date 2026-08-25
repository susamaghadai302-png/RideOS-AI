import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { ConfigService } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';
import { Rider, RiderSchema } from '../riders/schemas/rider.schema';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { JwtStrategy } from './jwt.strategy';
import { OAuthVerifierService } from './services/oauth-verifier.service';
import { SmsOtpService } from './services/sms-otp.service';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Rider.name, schema: RiderSchema }]),
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.registerAsync({
      useFactory: (configService: ConfigService) => ({
        secret: configService.get<string>('JWT_SECRET', 'super_secret_rideos_jwt_key_2026'),
        signOptions: {
          expiresIn: configService.get<string>('JWT_EXPIRATION', '7d'),
        },
      }),
      inject: [ConfigService],
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtStrategy, OAuthVerifierService, SmsOtpService],
  exports: [AuthService, JwtStrategy, OAuthVerifierService, SmsOtpService, PassportModule],
})
export class AuthModule {}
