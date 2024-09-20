import { Injectable } from '@nestjs/common';
import {
  Album,
  AlbumsOnMemory,
  Memory,
  MemoryFileType,
  PrismaClient,
} from '@prisma/client';
import { ITXClientDenyList } from '@prisma/client/runtime/library';
import { PrismaService } from 'src/lib/database/prisma.service';

@Injectable()
export class AlbumsOnMemoryRepository {
  constructor(private readonly prismaService: PrismaService) {}

  /**
   * 앨범에 추억을 추가
   */
  async create(dto: CreateDto): Promise<void> {
    await this.prismaService.albumsOnMemory.create({
      data: {
        albumId: dto.album.id,
        memoryId: dto.memory.id,
      },
    });
  }

  /**
   * 앨범별 추억 개수를 조회합니다.
   */
  async countByAlbumIds(dto: CountByAlbumIdsDto) {
    return await this.prismaService.albumsOnMemory.groupBy({
      by: ['albumId'],
      where: {
        albumId: {
          in: dto.albumIds,
        },
      },
      _count: {
        _all: true,
      },
    });
  }

  async findLastMemoryByAlbumIds(dto: FindLastMemoryByAlbumIdsDto) {
    return await this.prismaService.albumsOnMemory.findMany({
      include: {
        Memory: {
          include: {
            MemoryFile: {
              where: {
                type: MemoryFileType.IMAGE,
              },
              take: 1,
            },
          },
        },
      },
      distinct: ['albumId'],
      where: {
        albumId: {
          in: dto.albumIds,
        },
      },
      orderBy: {
        id: 'desc',
      },
    });
  }

  async deleteByAlbumId(dto: DeleteByAlbumIdDto): Promise<void> {
    await dto.tx.albumsOnMemory.deleteMany({
      where: {
        albumId: dto.albumId,
      },
    });
  }

  /**
   * 앨범에 추가된 추억 조회
   */
  async findUnique(dto: FindUniqueDto): Promise<AlbumsOnMemory | null> {
    return await this.prismaService.albumsOnMemory.findFirst({
      where: {
        albumId: dto.albumId,
        memoryId: dto.memoryId,
      },
    });
  }

  /**
   * 앨범에서 추억 삭제
   */
  async delete(dto: DeleteDto): Promise<void> {
    await this.prismaService.albumsOnMemory.delete({
      where: {
        id: dto.albumOnMemory.id,
      },
    });
  }

  /**
   * 앨범내의 추억 ids의 개수를 조회합니다.
   */
  async countByMemoryIds(dto: CountByMemoryIdsDto): Promise<number> {
    return await this.prismaService.albumsOnMemory.count({
      where: {
        albumId: dto.album.id,
        memoryId: {
          in: dto.memories.map((memory) => memory.id),
        },
      },
    });
  }
}

type CreateDto = {
  album: Album;
  memory: Memory;
};

type CountByAlbumIdsDto = {
  albumIds: number[];
};

type FindLastMemoryByAlbumIdsDto = {
  albumIds: number[];
};

type DeleteByAlbumIdDto = {
  tx: Omit<PrismaClient, ITXClientDenyList>;
  albumId: number;
};

type FindUniqueDto = {
  albumId: number;
  memoryId: number;
};

type DeleteDto = {
  albumOnMemory: AlbumsOnMemory;
};

type CountByMemoryIdsDto = {
  album: Album;
  memories: Memory[];
};
