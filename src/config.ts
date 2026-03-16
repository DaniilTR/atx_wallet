import 'dotenv/config';
import { z } from 'zod';

const envSchema = z.object({
  HOST: z.string().default('0.0.0.0'),
  PORT: z.coerce.number().int().positive().default(8080),
  COINGECKO_BASE_URL: z.string().url().default('https://api.coingecko.com'),
  CORS_ORIGINS: z.string().optional().default(''),
  CACHE_TTL_SECONDS: z.coerce.number().int().positive().default(300),
  CACHE_STALE_SECONDS: z.coerce.number().int().positive().default(86400),
  // Бэкапы кэша (снапшоты)
  // Интервал создания снапшотов (сек). 12 часов => 2 снапшота в сутки.
  CACHE_SNAPSHOT_INTERVAL_SECONDS: z.coerce.number().int().positive().default(43200),
  // Сколько снапшотов хранить на одну дату.
  CACHE_SNAPSHOTS_PER_DAY: z.coerce.number().int().positive().max(24).default(2),
  // Сколько дней хранить дневные файлы кэша. 0 = не чистить (хранить всегда).
  CACHE_DAILY_RETENTION_DAYS: z.coerce.number().int().nonnegative().default(0),
  REFRESH_INTERVAL_SECONDS: z.coerce.number().int().positive().default(240),
  PRELOAD_SIMPLE_PRICE_IDS: z.string().optional().default('bitcoin,ethereum,tether'),
  // market_chart (графики): какие монеты/диапазоны держим отдельными файлами
  MARKET_CHART_COINS: z
    .string()
    .optional()
    .default('bitcoin,ethereum,solana,ripple,binancecoin,litecoin,cosmos,tron'),
  MARKET_CHART_DAYS: z.string().optional().default('1,7,30,365'),
  UPSTREAM_TIMEOUT_MS: z.coerce.number().int().positive().default(10000),
  // Новости (RSS)
  NEWS_REFRESH_INTERVAL_SECONDS: z.coerce.number().int().positive().default(3600),
  NEWS_LIMIT: z.coerce.number().int().positive().max(50).default(15),
  NEWS_TTL_SECONDS: z.coerce.number().int().positive().default(3600),
  NEWS_STALE_SECONDS: z.coerce.number().int().positive().default(86400),
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
  cacheSnapshotIntervalSeconds: parsed.data.CACHE_SNAPSHOT_INTERVAL_SECONDS,
  cacheSnapshotsPerDay: parsed.data.CACHE_SNAPSHOTS_PER_DAY,
  cacheDailyRetentionDays: parsed.data.CACHE_DAILY_RETENTION_DAYS,
  refreshIntervalSeconds: parsed.data.REFRESH_INTERVAL_SECONDS,
  preloadSimplePriceIds: parsed.data.PRELOAD_SIMPLE_PRICE_IDS
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean),
  marketChartCoinIds: parsed.data.MARKET_CHART_COINS
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean),
  marketChartDays: parsed.data.MARKET_CHART_DAYS
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean)
    .map((s) => Number(s))
    .filter((n) => Number.isFinite(n) && n > 0) as number[],
  upstreamTimeoutMs: parsed.data.UPSTREAM_TIMEOUT_MS,
  newsRefreshIntervalSeconds: parsed.data.NEWS_REFRESH_INTERVAL_SECONDS,
  newsLimit: parsed.data.NEWS_LIMIT,
  newsTtlSeconds: parsed.data.NEWS_TTL_SECONDS,
  newsStaleSeconds: parsed.data.NEWS_STALE_SECONDS
};
