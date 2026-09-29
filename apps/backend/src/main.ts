import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';
import { HttpExceptionFilter } from './core/filters/http-exception.filter';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Enable graceful shutdown hooks for SIGTERM / SIGINT in production containers
  app.enableShutdownHooks();

  // Security Headers Middleware
  app.use((req: any, res: any, next: () => void) => {
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('X-Frame-Options', 'DENY');
    res.setHeader('X-XSS-Protection', '1; mode=block');
    res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
    res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
    next();
  });

  // Environment-Aware Hardened CORS Configuration
  app.enableCors({
    origin: (origin: string | undefined, callback: (err: Error | null, allow?: boolean) => void) => {
      if (!origin) return callback(null, true);
      const allowedOrigins = [
        'http://localhost:8080',
        'http://127.0.0.1:8080',
        'http://localhost:3000',
        'https://rideos.ai',
        'https://app.rideos.ai',
        'https://rideos-ai.web.app',
        'https://rideos-ai.firebaseapp.com',
      ];
      const isDevelopment = process.env.NODE_ENV !== 'production';
      const configuredOrigins = (process.env.CORS_ALLOWED_ORIGINS ?? '')
        .split(',')
        .map((value) => value.trim())
        .filter(Boolean);
      const defaultOrigins = [
        'https://rideos.ai',
        'https://app.rideos.ai',
        'https://rideos-ai.web.app',
        'https://rideos-ai.firebaseapp.com',
      ];
      const allowedOrigins = configuredOrigins.length > 0 ? configuredOrigins : defaultOrigins;
      const localOriginAllowed =
        isDevelopment &&
        (origin.startsWith('http://localhost:') ||
          origin.startsWith('http://127.0.0.1:'));
      if (allowedOrigins.includes(origin) || localOriginAllowed) {
        return callback(null, true);
      }
      return callback(new Error('CORS origin not allowed'), false);
    },
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    allowedHeaders: 'Content-Type,Accept,Authorization,X-Client-Platform,X-Client-Version',
    credentials: true,
  });

  // Global API Prefix
  app.setGlobalPrefix('api/v1');

  // Global Validation Pipe with whitelist & transform enabled
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );

  // Global Exception Filter
  app.useGlobalFilters(new HttpExceptionFilter());

  // Swagger OpenAPI Setup
  const swaggerConfig = new DocumentBuilder()
    .setTitle('RoadOS AI API')
    .setDescription('Enterprise Two-Wheeler Navigation, Telematics & AI Assistant Platform API')
    .setVersion('1.0.0')
    .addBearerAuth()
    .build();
  
  const document = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup('api/docs', app, document);

  const port = process.env.PORT || 3000;
  await app.listen(port, '0.0.0.0');
  console.log(`[RoadOS Backend] Service successfully started on port ${port}`);
  console.log(`[RoadOS Swagger] Documentation available at http://localhost:${port}/api/docs`);
}

bootstrap();
