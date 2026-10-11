import { IsIn, IsInt, IsOptional } from 'class-validator';
import { EVENT_TYPES, EventType } from '../achievements.service';

export class EventDto {
  @IsIn(EVENT_TYPES as unknown as string[], { message: 'Nieznany typ zdarzenia' })
  type: EventType;

  @IsOptional()
  @IsInt()
  monumentId?: number;
}
