import { IsString, IsOptional } from 'class-validator';

export class CreateSquadDto {
  @IsString()
  title: string;

  @IsString()
  @IsOptional()
  routeId?: string;
}
