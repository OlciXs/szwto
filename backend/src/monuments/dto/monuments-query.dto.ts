import { MonumentCategory, Rarity } from '@prisma/client';
import { IsEnum, IsOptional } from 'class-validator';

export class MonumentsQueryDto {
  @IsOptional()
  @IsEnum(MonumentCategory, { message: 'Nieznana kategoria' })
  category?: MonumentCategory;

  @IsOptional()
  @IsEnum(Rarity, { message: 'Nieznana rzadkość' })
  rarity?: Rarity;
}
