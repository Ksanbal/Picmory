import { Module } from '@nestjs/common';
import { AlbumsController } from 'src/1-presentation/controller/albums/albums.controller';
import { AlbumsFacade } from 'src/2-application/facade/albums/albums.facade';
import { AlbumsService } from 'src/3-domain/service/albums/albums.service';
import { AlbumRepository } from 'src/4-infrastructure/repository/albums/album.repository';
import { PrismaService } from 'src/lib/database/prisma.service';
import { MemoriesModule } from '../memories/memories.module';
import { AlbumMemoryRepository } from 'src/4-infrastructure/repository/albums/album-memory.repository';

@Module({
  imports: [MemoriesModule],
  controllers: [AlbumsController],
  providers: [
    PrismaService,
    AlbumsFacade,
    AlbumsService,
    AlbumRepository,
    AlbumMemoryRepository,
  ],
})
export class AlbumsModule {}
