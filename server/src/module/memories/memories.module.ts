import { Module } from '@nestjs/common';
import { MemoriesController } from 'src/1-presentation/controller/memories/memories.controller';
import { MemoriesFacade } from 'src/2-application/facade/memories/memories.facade';
import { MemoriesService } from 'src/3-domain/service/memories/memories.service';
import { MemoryFileRepository } from 'src/4-infrastructure/repository/memories/memory-file.repository';
import { PrismaService } from 'src/lib/database/prisma.service';
import { FileModule } from '../file/file.module';
import { MemoriesEventHandler } from 'src/1-presentation/event/memories/memories.event';

@Module({
  imports: [FileModule],
  controllers: [MemoriesController],
  providers: [
    PrismaService,
    MemoriesFacade,
    MemoriesService,
    MemoryFileRepository,
    MemoriesEventHandler,
  ],
})
export class MemoriesModule {}
