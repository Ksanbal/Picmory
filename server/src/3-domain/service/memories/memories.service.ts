import { BadRequestException, Injectable } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import {
  Memory,
  MemoryFile,
  MemoryFileType,
  PrismaClient,
} from '@prisma/client';
import { ITXClientDenyList } from '@prisma/client/runtime/library';
import { MemoryFileRepository } from 'src/4-infrastructure/repository/memories/memory-file.repository';
import { MemoryRepository } from 'src/4-infrastructure/repository/memories/memory.repository';
import { ERROR_MESSAGES } from 'src/lib/constants/error-messages';
import { EVENT_NAMES } from 'src/lib/constants/event-names';

@Injectable()
export class MemoriesService {
  constructor(
    private readonly memoryFileRepository: MemoryFileRepository,
    private readonly memoryRepository: MemoryRepository,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  /**
   * 파일 업로드
   */
  async upload(dto: UploadDto): Promise<MemoryFile> {
    const { sub, file } = dto;

    const type = file.mimetype.includes('image')
      ? MemoryFileType.IMAGE
      : MemoryFileType.VIDEO;

    // 파일 정보 저장
    const newFile = await this.memoryFileRepository.create({
      memberId: sub,
      type,
      originalName: file.originalname,
      size: file.size,
      path: file.path,
    });

    // 파일 생성 이벤트 발행
    this.eventEmitter.emit(EVENT_NAMES.MEMORIES_FILE_CREATED, {
      memoryFile: newFile,
    });

    return newFile;
  }

  /**
   * 파일 정보 업데이트
   */
  async updateMemoryFile(dto: UpdateMemoryFileDto): Promise<void> {
    const { memoryFile } = dto;

    await this.memoryFileRepository.update({
      memoryFile,
    });
  }

  /**
   * 유효한 파일 아이디인지 확인
   */
  async validateFileIds(dto: ValidateFileIdsDto): Promise<void> {
    const { memberId, ids } = dto;

    const files = await this.memoryFileRepository.findAllByIds({
      memberId,
      ids,
    });

    if (files.length !== ids.length) {
      throw new BadRequestException(ERROR_MESSAGES.MEMORIES_INVALID_FILE_IDS);
    }
  }

  /**
   * 기억 생성
   */
  async create(dto: CreateDto): Promise<Memory> {
    const { tx, memberId, brandName, date } = dto;

    const newMemory = await this.memoryRepository.create({
      tx,
      memberId,
      brandName,
      date,
    });

    if (newMemory == null) {
      throw new BadRequestException(ERROR_MESSAGES.MEMORIES_FAILED_CREATE);
    }

    return newMemory;
  }

  /**
   * linkMemoryFiles
   */
  async linkMemoryFiles(dto: LinkMemoryFilesDto): Promise<void> {
    const { tx, fileIds, memoryId } = dto;

    await this.memoryFileRepository.linkManyToMemory({
      tx,
      fileIds,
      memoryId,
    });
  }
}

type UploadDto = {
  sub: number;
  file: Express.Multer.File;
};

type UpdateMemoryFileDto = {
  memoryFile: MemoryFile;
};

type ValidateFileIdsDto = {
  memberId: number;
  ids: number[];
};

type CreateDto = {
  tx: Omit<PrismaClient, ITXClientDenyList>;
  memberId: number;
  brandName: string;
  date: Date;
};

type LinkMemoryFilesDto = {
  tx: Omit<PrismaClient, ITXClientDenyList>;
  fileIds: number[];
  memoryId: number;
};
