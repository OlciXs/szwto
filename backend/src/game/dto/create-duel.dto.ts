import { IsBoolean, IsInt, IsOptional } from 'class-validator';

export class CreateDuelDto {
  /** Id znajomego, z którym chcemy zagrać. Jeśli brak lub isBot: true – gra treningowa z rywalem. */
  @IsOptional()
  @IsInt()
  opponentId?: number;

  @IsOptional()
  @IsBoolean()
  isBot?: boolean;
}
