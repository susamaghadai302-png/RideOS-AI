import { Controller, Get, Post, Delete, Body, Param } from '@nestjs/common';
import { DigitalTwinService } from './digital_twin.service';
import { ReconstructDigitalTwinDto, SaveDigitalTwinDto } from './dto/digital_twin.dto';

@Controller('digital-twin')
export class DigitalTwinController {
  constructor(private readonly digitalTwinService: DigitalTwinService) {}

  @Post('reconstruct')
  async reconstruct(@Body() dto: ReconstructDigitalTwinDto) {
    return this.digitalTwinService.reconstruct(dto);
  }

  @Post('save')
  async save(@Body() dto: SaveDigitalTwinDto) {
    return this.digitalTwinService.save(dto);
  }

  @Get(':id')
  async getById(@Param('id') id: string) {
    return this.digitalTwinService.getById(id);
  }

  @Delete(':id')
  async delete(@Param('id') id: string) {
    return this.digitalTwinService.delete(id);
  }

  @Post('privacy/purge-photos/:twinId')
  async purgePhotos(@Param('twinId') twinId: string) {
    return this.digitalTwinService.purgePhotos(twinId);
  }
}
