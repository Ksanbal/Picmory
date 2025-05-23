import { Injectable } from '@nestjs/common';
import { MemoryFile, PrismaClient } from '@prisma/client';
import { ITXClientDenyList } from '@prisma/client/runtime/library';
import { PrismaService } from 'src/lib/database/prisma.service';
import { MemoryFileType } from 'src/lib/enums/memory-file-type.enum';

@Injectable()
export class MemoryFileRepository {
  constructor(private readonly prisma: PrismaService) {}

  async create(dto: CreateDto): Promise<MemoryFile> {
    return await this.prisma.memoryFile.create({
      data: {
        memoryId: null,
        thumbnailPath: null,
        ...dto,
      },
    });
  }

  async createMany(dto: CreateManyDto) {
    const { tx, memories } = dto;

    return await tx.memoryFile.createMany({
      data: memories,
    });
  }

  async update(dto: UpdateDto) {
    return await this.prisma.memoryFile.update({
      where: { id: dto.memoryFile.id },
      data: {
        ...dto.memoryFile,
      },
    });
  }

  async updateWithId(dto: UpdateWithIdDto) {
    return await this.prisma.memoryFile.update({
      where: { id: dto.id },
      data: {
        ...dto.data,
      },
    });
  }

  /**
   * 해당 사용자가 업로드한 파일들이고 memory랑 연결되지 않은 파일들을 가져옴
   */
  async findAllByIds(dto: FindAllByIdsDto) {
    return await this.prisma.memoryFile.findMany({
      where: {
        id: {
          in: dto.ids,
        },
        memberId: dto.memberId,
        memoryId: null,
      },
    });
  }

  /**
   * 여러 파일을 memory에 연결
   */
  async linkManyToMemory(dto: LinkManyToMemoryDto) {
    await dto.tx.memoryFile.updateMany({
      where: {
        id: {
          in: dto.fileIds,
        },
      },
      data: {
        memoryId: dto.memoryId,
      },
    });
  }

  /**
   * 여러 파일을 memoryId를 이용해서 삭제
   */
  async deleteManyByMemoryId(dto: DeleteManyByMemoryIdDto) {
    await dto.tx.memoryFile.updateMany({
      where: {
        memoryId: dto.memoryId,
      },
      data: {
        deletedAt: new Date(),
      },
    });
  }
}

type CreateDto = {
  memberId: number;
  type: MemoryFileType;
  originalName: string;
  size: number;
  path: string;
};

type CreateManyDto = {
  tx: Omit<PrismaClient, ITXClientDenyList>;
  memories: CreateManyDtoMemory[];
};

type CreateManyDtoMemory = {
  memberId: number;
  memoryId: number;
  type: MemoryFileType;
  originalName: string;
  path: string;
};

type UpdateDto = {
  memoryFile: MemoryFile;
};

type UpdateWithIdDto = {
  id: number;
  data: any;
};

type FindAllByIdsDto = {
  memberId: number;
  ids: number[];
};

type LinkManyToMemoryDto = {
  tx: Omit<PrismaClient, ITXClientDenyList>;
  fileIds: number[];
  memoryId: number;
};

type DeleteManyByMemoryIdDto = {
  tx: Omit<PrismaClient, ITXClientDenyList>;
  memoryId: number;
};
