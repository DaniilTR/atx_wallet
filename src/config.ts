import 'dotenv/config';
import { z } from 'zod';

const envSchema = z.object({
  HOST: z.string().default('0.0.0.0'),
  PORT: z.coerce.number().int().positive().default(8080),
  COINGECKO_BASE_URL: z.string().url().default('https://api.coingecko.com'),
  CORS_ORIGINS: z.string().optional().default(''),
  CACHE_TTL_SECONDS: z.coerce.number().int().positive().default(300),
  CACHE_STALE_SECONDS: z.coerce.number().int().positive().default(86400),
  REFRESH_INTERVAL_SECONDS: z.coerce.number().int().positive().default(240),
  PRELOAD_SIMPLE_PRICE_IDS: z.string().optional().default('bitcoin,ethereum,tether'),
  UPSTREAM_TIMEOUT_MS: z.coerce.number().int().positive().default(10000),
  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace']).default('info')
});

const parsed = envSchema.safeParse(process.env);
if (!parsed.success) {
  // Русское сообщение, чтобы на VPS было ясно, что чинить.
  // eslint-disable-next-line no-console
  console.error('Ошибка конфигурации .env:', parsed.error.flatten().fieldErrors);
  process.exit(1);
}

export const config = {
  host: parsed.data.HOST,
  port: parsed.data.PORT,
  logLevel: parsed.data.LOG_LEVEL,
  coingeckoBaseUrl: parsed.data.COINGECKO_BASE_URL,
  corsOrigins: parsed.data.CORS_ORIGINS
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean),
  cacheTtlSeconds: parsed.data.CACHE_TTL_SECONDS,
  cacheStaleSeconds: parsed.data.CACHE_STALE_SECONDS,
  refreshIntervalSeconds: parsed.data.REFRESH_INTERVAL_SECONDS,
  preloadSimplePriceIds: parsed.data.PRELOAD_SIMPLE_PRICE_IDS
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean),
  upstreamTimeoutMs: parsed.data.UPSTREAM_TIMEOUT_MS
};
