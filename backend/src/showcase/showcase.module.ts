import { Module } from '@nestjs/common';

/**
 * Tor D – gablotka na profilu (issue #4).
 *
 * Plan:
 *   - tabela ShowcaseSlot (slot 0-4), wystawić można tylko odwiedzony zabytek
 *   - PUT /showcase/:slot { monumentId }, DELETE /showcase/:slot
 *   - dane gablotki zwracane w profilu publicznym (users/)
 */
@Module({})
export class ShowcaseModule {}
