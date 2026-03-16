import Fastify from 'fastify';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { config } from './config.js';
import { JsonFileCache } from './cache/json_file_cache.js';
import { CoinGeckoCachedClient } from './coingecko/coingecko_cache.js';
import { registerCoinGeckoRoutes } from './routes/coingecko_routes.js';

const app = Fastify({
  logger: {
    level: config.logLevel
  }
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
const cacheFilePath = join(here, '..', 'data', 'cache.json');
const cache = new JsonFileCache(cacheFilePath);
await cache.load();

const cg = new CoinGeckoCachedClient({
  baseUrl: config.coingeckoBaseUrl,
  cache
});

await registerCoinGeckoRoutes(app, { cg });

try {
  await app.listen({ host: config.host, port: config.port });
  app.log.info(`server_for_atx listening on http://${config.host}:${config.port}`);
} catch (err) {
  app.log.error(err);
  process.exit(1);
}
