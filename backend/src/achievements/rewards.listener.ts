import { Injectable } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import {
  MONUMENT_VISITED,
  MonumentVisitedEvent,
  VisitRewards,
} from '../events/monument-visited.event';
import { RewardsService } from './rewards.service';

/** Po pierwszej wizycie: osiągnięcia + poziom -> pole `rewards` w odpowiedzi wizyty. */
@Injectable()
export class RewardsListener {
  constructor(private readonly rewards: RewardsService) {}

  @OnEvent(MONUMENT_VISITED)
  handle(event: MonumentVisitedEvent): Promise<VisitRewards> {
    return this.rewards.settle(event.userId, event.visit.xpEarned);
  }
}
