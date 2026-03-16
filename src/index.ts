import Fastify from 'fastify';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { config } from './config.js';
import { JsonFileCache } from './cache/json_file_cache.js';
import { CoinGeckoCachedClient } from './coingecko/coingecko_cache.js';
import { registerCoinGeckoRoutes } from './routes/coingecko_routes.js';
import { registerNewsRoutes } from './routes/news_routes.js';
import { NewsService } from './news/news_cache.js';

const app = Fastify({
  logger: {
    level: config.logLevel
  }
});

// На проде лучше перезапускать процесс через pm2/systemd, но по требованиям проекта
// сервер не должен «падать» даже при неожиданных ошибках.
process.on('unhandledRejection', (reason) => {
  app.log.error({ reason }, 'unhandledRejection');
});

process.on('uncaughtException', (err) => {
  app.log.error({ err }, 'uncaughtException');
});

await app.register(helmet);

await app.register(cors, {
  origin: (
    origin: string | undefined,
    cb: (err: Error | null, allow: boolean) => void
  ) => {
    // Если origin пустой (например, curl или server-to-server) — разрешаем.
    if (!origin) return cb(null, true);
    // Если список пуст, то разрешаем всё (удобно для тестов и MVP).
    if (config.corsOrigins.length === 0) return cb(null, true);
    cb(null, config.corsOrigins.includes(origin));
  }
});

app.get('/healthz', async () => {
  return { ok: true };
});

const here = dirname(fileURLToPath(import.meta.url));
const cacheRoot = join(here, '..', 'data', 'cache');
const coingeckoRoot = join(cacheRoot, 'coingecko');

const makeCache = (opts: { name: string; currentFilePath: string; dailyDir: string; snapshotsDir: string }) => {
  const cache = new JsonFileCache({
    name: opts.name,
    currentFilePath: opts.currentFilePath,
    dailyDir: opts.dailyDir,
    snapshotsDir: opts.snapshotsDir,
    snapshotsPerDay: config.cacheSnapshotsPerDay,
    dailyRetentionDays: config.cacheDailyRetentionDays === 0 ? undefined : config.cacheDailyRetentionDays
  });
  return cache;
};

// 1) simple/price — отдельный файл
const simplePriceCache = makeCache({
  name: 'simple_price',
  currentFilePath: join(coingeckoRoot, 'simple_price.json'),
  dailyDir: join(coingeckoRoot, 'simple_price', 'daily'),
  snapshotsDir: join(coingeckoRoot, 'simple_price', 'snapshots')
});
await simplePriceCache.load();
await simplePriceCache.flush();
simplePriceCache.startAutoSnapshots(config.cacheSnapshotIntervalSeconds * 1000);

// 2) coins/markets — отдельный файл
const coinsMarketsCache = makeCache({
  name: 'coins_markets',
  currentFilePath: join(coingeckoRoot, 'coins_markets.json'),
  dailyDir: join(coingeckoRoot, 'coins_markets', 'daily'),
  snapshotsDir: join(coingeckoRoot, 'coins_markets', 'snapshots')
});
await coinsMarketsCache.load();
await coinsMarketsCache.flush();
coinsMarketsCache.startAutoSnapshots(config.cacheSnapshotIntervalSeconds * 1000);

// Фолбэк-кэш для market_chart (если прилетит coin/days вне списка)
const marketChartMiscCache = makeCache({
  name: 'market_chart_misc',
  currentFilePath: join(coingeckoRoot, 'market_chart_misc.json'),
  dailyDir: join(coingeckoRoot, 'market_chart_misc', 'daily'),
  snapshotsDir: join(coingeckoRoot, 'market_chart_misc', 'snapshots')
});
await marketChartMiscCache.load();
await marketChartMiscCache.flush();
marketChartMiscCache.startAutoSnapshots(config.cacheSnapshotIntervalSeconds * 1000);

// 3) market_chart — отдельная папка на каждую монету, внутри 4 файла (days=1/7/30/365)
const marketChartCaches = new Map<string, JsonFileCache>();
for (const coinId of config.marketChartCoinIds) {
  for (const days of config.marketChartDays) {
    const coinDir = join(coingeckoRoot, 'market_chart', coinId);
    const cache = makeCache({
      name: `market_chart_${coinId}_${days}d`,
      currentFilePath: join(coinDir, `days_${days}.json`),
      dailyDir: join(coinDir, 'daily'),
      snapshotsDir: join(coinDir, 'snapshots')
    });
    await cache.load();
    await cache.flush();
    cache.startAutoSnapshots(config.cacheSnapshotIntervalSeconds * 1000);
    marketChartCaches.set(`${coinId}:${days}`, cache);
  }
}

const newsCache = new JsonFileCache({
  name: 'news',
  currentFilePath: join(cacheRoot, 'news_current.json'),
  dailyDir: join(cacheRoot, 'daily'),
  snapshotsDir: join(cacheRoot, 'snapshots'),
  snapshotsPerDay: config.cacheSnapshotsPerDay,
  dailyRetentionDays: config.cacheDailyRetentionDays === 0 ? undefined : config.cacheDailyRetentionDays
});
await newsCache.load();
await newsCache.flush();
newsCache.startAutoSnapshots(config.cacheSnapshotIntervalSeconds * 1000);

const cg = new CoinGeckoCachedClient({
  baseUrl: config.coingeckoBaseUrl,
  cacheProvider: (pathname, query) => {
    if (pathname === '/api/v3/simple/price') return simplePriceCache;
    if (pathname === '/api/v3/coins/markets') return coinsMarketsCache;

    // /api/v3/coins/:id/market_chart
    const m = pathname.match(/^\/api\/v3\/coins\/([^/]+)\/market_chart$/);
    if (m) {
      const coinId = decodeURIComponent(m[1] ?? '');
      const daysRaw = query?.days;
      const days = typeof daysRaw === 'number'
        ? daysRaw
        : typeof daysRaw === 'string'
          ? Number(daysRaw)
          : NaN;
      if (Number.isFinite(days)) {
        const found = marketChartCaches.get(`${coinId}:${days}`);
        if (found) return found;
      }

      return marketChartMiscCache;
    }

    // Фолбэк: всё прочее (если вдруг появятся новые запросы) кладём в общий coins_markets.
    return coinsMarketsCache;
  }
});

const news = new NewsService(newsCache);

await registerCoinGeckoRoutes(app, { cg });
await registerNewsRoutes(app, { news });

try {
  await app.listen({ host: config.host, port: config.port });
  app.log.info(`server_for_atx listening on http://${config.host}:${config.port}`);
} catch (err) {
  app.log.error(err);
  process.exit(1);
}
