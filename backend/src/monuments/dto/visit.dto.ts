import { IsNumber, Max, Min } from 'class-validator';

export class VisitDto {
  @IsNumber({}, { message: 'latitude musi być liczbą' })
  @Min(-90)
  @Max(90)
  latitude: number;

  @IsNumber({}, { message: 'longitude musi być liczbą' })
  @Min(-180)
  @Max(180)
  longitude: number;
}
