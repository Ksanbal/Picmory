import { Expose } from 'class-transformer';

export class RefreshResDto {
  @Expose()
  accessToken: string;
}
