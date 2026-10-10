import {
  Body,
  Controller,
  Get,
  HttpCode,
  Param,
  ParseIntPipe,
  Post,
  UseGuards,
} from '@nestjs/common';
import { AuthUser, CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { VisitDto } from './dto/visit.dto';
import { MonumentsService } from './monuments.service';

@UseGuards(JwtAuthGuard)
@Controller('monuments')
export class MonumentsController {
  constructor(private readonly monumentsService: MonumentsService) {}

  @Get()
  findAll(@CurrentUser() user: AuthUser) {
    return this.monumentsService.findAllForUser(user.userId);
  }

  @Post(':id/visit')
  @HttpCode(200)
  visit(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: VisitDto,
  ) {
    return this.monumentsService.visit(user.userId, id, dto);
  }
}
