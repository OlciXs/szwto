import { randomInt } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';

/** Bez znaków łatwych do pomylenia (0/O, 1/I/L). */
const ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
const LENGTH = 6;

function randomCode(): string {
  return Array.from({ length: LENGTH }, () => ALPHABET[randomInt(ALPHABET.length)]).join('');
}

/** Losowy, wolny kod znajomego (np. "K7Q2MX"). */
export async function generateFriendCode(prisma: PrismaService): Promise<string> {
  for (let attempt = 0; attempt < 10; attempt++) {
    const code = randomCode();
    const taken = await prisma.user.findUnique({ where: { friendCode: code } });
    if (!taken) return code;
  }
  throw new Error('Nie udało się wygenerować kodu znajomego');
}

/** „#k7q2mx ” -> „K7Q2MX”. */
export function normalizeFriendCode(input: string): string {
  return input.trim().replace(/^#/, '').toUpperCase();
}
