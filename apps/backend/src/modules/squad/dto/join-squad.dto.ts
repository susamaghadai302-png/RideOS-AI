import { IsString, Length } from 'class-validator';

export class JoinSquadDto {
  @IsString()
  @Length(6, 6, { message: 'Squad code must be exactly 6 characters' })
  squadCode: string;
}
