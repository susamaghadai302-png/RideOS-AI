import { Controller, Get, Post, Delete, Param, Body, Query, UseGuards, Req } from '@nestjs/common';
import { TripsService } from './trips.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CreateTripDto, FinishTripDto, AddTripPointsDto, TripEventDto, LocationPointDto } from './dto/create-trip.dto';

@Controller('trips')
@UseGuards(JwtAuthGuard)
export class TripsController {
  constructor(private readonly tripsService: TripsService) {}

  @Post()
  async createOrSyncTrip(@Req() req: any, @Body() dto: CreateTripDto) {
    return this.tripsService.createOrSyncTrip(req.user.userId, dto);
  }

  @Get()
  async getUserTrips(
    @Req() req: any,
    @Query('limit') limit?: string,
    @Query('skip') skip?: string,
  ) {
    const lim = limit ? parseInt(limit, 10) : 20;
    const sk = skip ? parseInt(skip, 10) : 0;
    return this.tripsService.getUserTrips(req.user.userId, lim, sk);
  }

  @Get(':id')
  async getTripById(@Req() req: any, @Param('id') id: string) {
    return this.tripsService.getTripById(req.user.userId, id);
  }

  @Post(':id/start')
  async startTrip(
    @Req() req: any,
    @Param('id') id: string,
    @Body('vehicleId') vehicleId: string,
    @Body('startLocation') startLocation?: LocationPointDto,
  ) {
    return this.tripsService.startTrip(req.user.userId, id, vehicleId, startLocation);
  }

  @Post(':id/finish')
  async finishTrip(
    @Req() req: any,
    @Param('id') id: string,
    @Body() dto: FinishTripDto,
  ) {
    return this.tripsService.finishTrip(req.user.userId, id, dto);
  }

  @Post(':id/points')
  async addTripPoints(
    @Req() req: any,
    @Param('id') id: string,
    @Body() dto: AddTripPointsDto,
  ) {
    await this.tripsService.addTripPoints(req.user.userId, id, dto.points);
    return { success: true, pointsAdded: dto.points.length };
  }

  @Post(':id/events')
  async recordTripEvent(
    @Req() req: any,
    @Param('id') id: string,
    @Body() dto: TripEventDto,
  ) {
    await this.tripsService.recordTripEvent(req.user.userId, id, dto);
    return { success: true };
  }

  @Delete(':id')
  async deleteTrip(@Req() req: any, @Param('id') id: string) {
    return this.tripsService.deleteTrip(req.user.userId, id);
  }
}
