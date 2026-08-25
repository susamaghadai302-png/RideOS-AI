import { Controller, Post, Get, Body, Param, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { SquadService } from './squad.service';
import { CreateSquadDto } from './dto/create-squad.dto';
import { JoinSquadDto } from './dto/join-squad.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@ApiTags('Group Squad Rides')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('squad')
export class SquadController {
  constructor(private readonly squadService: SquadService) {}

  @Post('create')
  @ApiOperation({ summary: 'Create a new group ride squad room' })
  async createSquad(@Request() req: any, @Body() dto: CreateSquadDto) {
    return this.squadService.createSquad(req.user.userId, dto);
  }

  @Post('join')
  @ApiOperation({ summary: 'Join an active squad room using a 6-digit code' })
  async joinSquad(@Request() req: any, @Body() dto: JoinSquadDto) {
    return this.squadService.joinSquad(req.user.userId, dto);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get active squad room details and member locations' })
  async getSquad(@Param('id') id: string) {
    return this.squadService.getSquadById(id);
  }
}
