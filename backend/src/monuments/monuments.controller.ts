import {
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Query,
  UseGuards,
} from '@nestjs/common';
import { AuthUser, CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { MonumentsQueryDto } from './dto/monuments-query.dto';
import { MonumentsService } from './monuments.service';

@UseGuards(JwtAuthGuard)
@Controller('monuments')
export class MonumentsController {
  constructor(private readonly monumentsService: MonumentsService) {}

  /** Lista na mapę. Opcjonalnie ?category=KAMIENICA&rarity=EPIC */
  @Get()
  findAll(@CurrentUser() user: AuthUser, @Query() query: MonumentsQueryDto) {
    return this.monumentsService.findAllForUser(user.userId, query);
  }

  @Get(':id')
  findOne(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseIntPipe) id: number,
  ) {
    return this.monumentsService.findOneForUser(user.userId, id);
  }
}
