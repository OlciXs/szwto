import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '../prisma/prisma.service';
import { AuthDto, RegisterDto } from './dto/auth.dto';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
  ) {}

  async register(dto: RegisterDto) {
    const email = dto.email.trim().toLowerCase();

    const existing = await this.prisma.user.findUnique({ where: { email } });
    if (existing) {
      throw new ConflictException(
        'Użytkownik z takim adresem e-mail już istnieje',
      );
    }

    let displayName: string;
    if (dto.displayName) {
      displayName = dto.displayName.trim();
      const taken = await this.prisma.user.findUnique({
        where: { displayName },
      });
      if (taken) {
        throw new ConflictException('Ta nazwa gracza jest już zajęta');
      }
    } else {
      displayName = await this.generateDisplayName(email);
    }

    const password = await bcrypt.hash(dto.password, 10);
    const user = await this.prisma.user.create({
      data: { email, password, displayName },
    });

    return this.buildResponse(user);
  }

  async login(dto: AuthDto) {
    const email = dto.email.trim().toLowerCase();

    const user = await this.prisma.user.findUnique({ where: { email } });
    const passwordOk =
      user !== null && (await bcrypt.compare(dto.password, user.password));

    if (!user || !passwordOk) {
      throw new UnauthorizedException('Nieprawidłowy e-mail lub hasło');
    }

    return this.buildResponse(user);
  }

  /** "jan.kowalski@x.pl" -> "jan.kowalski", przy kolizji dopisuje losowe cyfry. */
  private async generateDisplayName(email: string): Promise<string> {
    const base =
      email
        .split('@')[0]
        .replace(/[^\p{L}\d_.-]/gu, '')
        .slice(0, 18) || 'gracz';
    const padded = base.length >= 3 ? base : `gracz_${base}`;

    for (let attempt = 0; attempt < 10; attempt++) {
      const candidate =
        attempt === 0
          ? padded
          : `${padded}_${Math.floor(1000 + Math.random() * 9000)}`;
      const taken = await this.prisma.user.findUnique({
        where: { displayName: candidate },
      });
      if (!taken) return candidate;
    }
    return `gracz_${Date.now()}`;
  }

  private async buildResponse(user: {
    id: number;
    email: string;
    displayName: string;
  }) {
    const accessToken = await this.jwt.signAsync({
      sub: user.id,
      email: user.email,
    });
    return {
      accessToken,
      user: { id: user.id, email: user.email, displayName: user.displayName },
    };
  }
}
