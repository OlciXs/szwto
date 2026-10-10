import {
  IsEmail,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';

export class AuthDto {
  @IsEmail({}, { message: 'Podaj poprawny adres e-mail' })
  email: string;

  @IsString()
  @MinLength(6, { message: 'Hasło musi mieć co najmniej 6 znaków' })
  password: string;
}

export const DISPLAY_NAME_PATTERN = /^[\p{L}\d_.-]{3,24}$/u;

export class RegisterDto extends AuthDto {
  /** Publiczna nazwa gracza. Gdy brak – generowana z adresu e-mail. */
  @IsOptional()
  @IsString()
  @MaxLength(24)
  @Matches(DISPLAY_NAME_PATTERN, {
    message: 'Nazwa gracza: 3–24 znaki (litery, cyfry, _ . -)',
  })
  displayName?: string;
}
