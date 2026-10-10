import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
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
}

bootstrap();
