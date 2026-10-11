import { Transform } from 'class-transformer';
import {
  IsNumber,
  IsString,
  Max,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';

export class CreateCommentDto {
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @MinLength(1, { message: 'Komentarz nie może być pusty' })
  @MaxLength(500, { message: 'Komentarz może mieć maks. 500 znaków' })
  body: string;

  /** Pozycja gracza – komentować można tylko na miejscu. */
  @IsNumber({}, { message: 'latitude musi być liczbą' })
  @Min(-90)
  @Max(90)
  latitude: number;

  @IsNumber({}, { message: 'longitude musi być liczbą' })
  @Min(-180)
  @Max(180)
  longitude: number;
}
