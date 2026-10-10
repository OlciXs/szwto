import {
  Body,
  Controller,
  HttpCode,
  Param,
  ParseIntPipe,
  Post,
  UseGuards,
} from '@nestjs/common';
import { AuthUser, CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { VisitDto } from './dto/visit.dto';
import { VisitsService } from './visits.service';

@UseGuards(JwtAuthGuard)
@Controller('monuments')
export class VisitsController {
  constructor(private readonly visitsService: VisitsService) {}

  @Post(':id/visit')
  @HttpCode(200)
  visit(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: VisitDto,
  ) {
    return this.visitsService.visit(user.userId, id, dto);
  }
}
