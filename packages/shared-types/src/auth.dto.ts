export interface RegisterRequestDto {
  email: string;
  password: string;
  fullName: string;
  phone: string;
}

export interface LoginRequestDto {
  email: string;
  password: string;
}

export interface AuthTokensDto {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

export interface AuthResponseDto {
  tokens: AuthTokensDto;
  rider: {
    id: string;
    email: string;
    fullName: string;
    phone: string;
  };
}
