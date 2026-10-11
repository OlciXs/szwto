import { Logger, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import {
  isAutoSetupEnabled,
  runMigrations,
  seedIfNeeded,
} from './database/database-setup';
import { PrismaService } from './prisma/prisma.service';

async function bootstrap() {
  // Na Renderze: tabele aktualizujemy przed startem (patrz database/database-setup.ts)
  const autoSetup = isAutoSetupEnabled();
  if (autoSetup) runMigrations();

  const app = await NestFactory.create(AppModule);

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
    }),
  );
  app.enableCors();

  const port = Number(process.env.PORT) || 3000;
  // 0.0.0.0 pozwala połączyć się z fizycznego telefonu w tej samej sieci Wi-Fi
  await app.listen(port, '0.0.0.0');
  console.log(`Backend działa na http://localhost:${port}`);

  // Seed w tle – serwer już przyjmuje żądania
  if (autoSetup) {
    seedIfNeeded(app.get(PrismaService)).catch((error) =>
      new Logger('DatabaseSetup').error(`Seed nieudany: ${error}`),
    );
  }
}

bootstrap();
