import { Controller, Post, Body, HttpCode, HttpStatus } from '@nestjs/common';
import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  async register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  @HttpCode(HttpStatus.OK)
  @Post('login')
  async login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  @HttpCode(HttpStatus.OK)
  @Post('refresh')
  async refresh(@Body() dto: RefreshTokenDto) {
    return this.authService.refresh(dto.refreshToken);
  }

  @HttpCode(HttpStatus.OK)
  @Post('oauth/google')
  async googleOAuth(@Body() body: { idToken?: string; accessToken?: string; email?: string; fullName?: string }) {
    return this.authService.loginWithGoogleOAuth(body);
  }

  @HttpCode(HttpStatus.OK)
  @Post('oauth/apple')
  async appleOAuth(@Body() body: { identityToken?: string; authorizationCode?: string; email?: string; fullName?: string }) {
    return this.authService.loginWithAppleOAuth(body);
  }

  @HttpCode(HttpStatus.OK)
  @Post('otp')
  async requestOtp(@Body() body: { phone: string; code?: string }) {
    if (body.code) {
      return this.authService.verifyOtp(body.phone, body.code);
    }
    return this.authService.requestOtp(body.phone);
  }

  @HttpCode(HttpStatus.OK)
  @Post('forgot-password')
  async forgotPassword(@Body() body: { email: string }) {
    return this.authService.forgotPassword(body.email);
  }
}
