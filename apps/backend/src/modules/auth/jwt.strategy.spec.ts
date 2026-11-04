import { UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtStrategy } from './jwt.strategy';

describe('JwtStrategy', () => {
  let strategy: JwtStrategy;

  const mockConfigService = {
    getOrThrow: jest.fn().mockReturnValue('test-jwt-secret'),
  } as unknown as ConfigService;

  beforeEach(() => {
    strategy = new JwtStrategy(mockConfigService);
  });

  it('should validate and extract user context with both sub and email', async () => {
    const payload = { sub: 'rider_12345', email: 'rider@example.com' };
    const user = await strategy.validate(payload);

    expect(user).toEqual({
      userId: 'rider_12345',
      sub: 'rider_12345',
      email: 'rider@example.com',
    });
  });

  it('should validate phone OTP accounts where email is omitted or empty', async () => {
    const payload = { sub: 'rider_phone_999' };
    const user = await strategy.validate(payload);

    expect(user).toEqual({
      userId: 'rider_phone_999',
      sub: 'rider_phone_999',
      email: '',
    });
  });

  it('should reject tokens missing a subject identifier (sub)', async () => {
    const payload = { sub: '', email: 'no_sub@example.com' };
    await expect(strategy.validate(payload)).rejects.toThrow(UnauthorizedException);
  });
});

