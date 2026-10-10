import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '../prisma/prisma.service';
import { AuthDto } from './dto/auth.dto';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
  ) {}

  async register(dto: AuthDto) {
    const email = dto.email.trim().toLowerCase();

    const existing = await this.prisma.user.findUnique({ where: { email } });
    if (existing) {
      throw new ConflictException(
        'Użytkownik z takim adresem e-mail już istnieje',
      );
    }

    const password = await bcrypt.hash(dto.password, 10);
    const user = await this.prisma.user.create({ data: { email, password } });

    return this.buildResponse(user.id, user.email);
  }

  async login(dto: AuthDto) {
    const email = dto.email.trim().toLowerCase();

    const user = await this.prisma.user.findUnique({ where: { email } });
    const passwordOk =
      user !== null && (await bcrypt.compare(dto.password, user.password));

    if (!user || !passwordOk) {
      throw new UnauthorizedException('Nieprawidłowy e-mail lub hasło');
    }

    return this.buildResponse(user.id, user.email);
  }

  private async buildResponse(id: number, email: string) {
    const accessToken = await this.jwt.signAsync({ sub: id, email });
    return { accessToken, user: { id, email } };
  }
}
