import { Module } from '@nestjs/common';
import { CloudSyncController } from './cloud-sync.controller';
import { CloudSyncService } from './cloud-sync.service';

@Module({
  controllers: [CloudSyncController],
  providers: [CloudSyncService],
  exports: [CloudSyncService],
})
export class CloudSyncModule {}
