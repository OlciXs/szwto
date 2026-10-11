import { ArrayMaxSize, ArrayMinSize, IsArray, IsIn, IsString } from 'class-validator';

export class SubmitAnswersDto {
  /** Wybory gracza dla kolejnych rund: 'CREATOR' lub 'OPPONENT'. */
  @IsArray()
  @ArrayMinSize(3)
  @ArrayMaxSize(3)
  @IsString({ each: true })
  @IsIn(['CREATOR', 'OPPONENT'], { each: true, message: 'Odpowiedź musi być CREATOR lub OPPONENT' })
  answers: ('CREATOR' | 'OPPONENT')[];
}
