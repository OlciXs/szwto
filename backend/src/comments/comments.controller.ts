import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { AuthUser, CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CommentsService } from './comments.service';
import { CreateCommentDto } from './dto/comment.dto';

@UseGuards(JwtAuthGuard)
@Controller()
export class CommentsController {
  constructor(private readonly comments: CommentsService) {}

  /** Komentarze od najnowszych. Kolejna strona: ?before=<id ostatniego>. */
  @Get('monuments/:id/comments')
  list(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseIntPipe) id: number,
    @Query('before') before?: string,
  ) {
    const cursor = before ? Number.parseInt(before, 10) : undefined;
    return this.comments.list(user.userId, id, Number.isFinite(cursor) ? cursor : undefined);
  }

  /** { body, latitude, longitude } – tylko po wizycie i na miejscu. */
  @Post('monuments/:id/comments')
  create(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: CreateCommentDto,
  ) {
    return this.comments.create(user.userId, id, dto);
  }

  @Delete('comments/:id')
  remove(@CurrentUser() user: AuthUser, @Param('id', ParseIntPipe) id: number) {
    return this.comments.remove(user.userId, id);
  }
}
