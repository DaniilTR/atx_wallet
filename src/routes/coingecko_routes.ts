import type { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';
import { config } from '../config.js';
import { CoinGeckoCachedClient } from '../coingecko/coingecko_cache.js';

// Явный allowlist: проксируем только то, что реально нужно приложению.
const allowed = {
  simplePrice: '/api/v3/simple/price',
  coinsMarkets: '/api/v3/coins/markets'
} as const;

function replyUpstreamError(reply: FastifyReply) {
  // Не отдаём детали апстрима наружу — только понятный статус.
  // Детали остаются в логах.
  return reply.code(502).send({
    error: 'UPSTREAM_UNAVAILABLE',
    message: 'Источник цен временно недоступен'
  });
}

export async function registerCoinGeckoRoutes(
  app: FastifyInstance,
  deps: { cg: CoinGeckoCachedClient }
): Promise<void> {
  // Простые цены
  app.get(allowed.simplePrice, async (
    req: FastifyRequest<{ Querystring: Record<string, unknown> }>,
    reply: FastifyReply
  ) => {
    try {
      const result = await deps.cg.getJson(allowed.simplePrice, req.query as Record<string, unknown>);
      reply.header('Content-Type', 'application/json');
      reply.header('X-Cache', result.cacheStatus);
      return reply.code(result.statusCode).send(result.body);
    } catch (err) {
      app.log.warn({ err }, 'CoinGecko simple/price failed');
      return replyUpstreamError(reply);
    }
  });

  // Топ монеты/рынок
  app.get(allowed.coinsMarkets, async (
    req: FastifyRequest<{ Querystring: Record<string, unknown> }>,
    reply: FastifyReply
  ) => {
    try {
      const result = await deps.cg.getJson(allowed.coinsMarkets, req.query as Record<string, unknown>);
      reply.header('Content-Type', 'application/json');
      reply.header('X-Cache', result.cacheStatus);
      return reply.code(result.statusCode).send(result.body);
    } catch (err) {
      app.log.warn({ err }, 'CoinGecko coins/markets failed');
      return replyUpstreamError(reply);
    }
  });

  // График: /api/v3/coins/:id/market_chart
  app.get('/api/v3/coins/:id/market_chart', async (
    req: FastifyRequest<{ Params: { id: string }; Querystring: Record<string, unknown> }>,
    reply: FastifyReply
  ) => {
    const params = req.params as { id: string };
    const pathname = `/api/v3/coins/${encodeURIComponent(params.id)}/market_chart`;

    try {
      const result = await deps.cg.getJson(pathname, req.query as Record<string, unknown>);
      reply.header('Content-Type', 'application/json');
      reply.header('X-Cache', result.cacheStatus);
      return reply.code(result.statusCode).send(result.body);
    } catch (err) {
      app.log.warn({ err, coinId: params.id }, 'CoinGecko market_chart failed');
      return replyUpstreamError(reply);
    }
  });

  // Фоновое обновление simple/price для заранее известных id.
  // Делается, чтобы в пике нагрузок приложение почти всегда получало HIT/STALE,
  // а CoinGecko не ловил шквал запросов.
  const preload = async (): Promise<void> => {
    if (config.preloadSimplePriceIds.length === 0) return;
    const query = {
      ids: config.preloadSimplePriceIds.join(','),
      vs_currencies: 'usd'
    };
    const key = deps.cg.keyFor(allowed.simplePrice, query);
    try {
      await deps.cg.fetchAndCache(key, allowed.simplePrice, query);
      app.log.debug({ ids: config.preloadSimplePriceIds }, 'Preloaded CoinGecko simple/price');
    } catch (e) {
      app.log.warn({ err: e }, 'Preload CoinGecko failed');
    }
  };

  // Стартуем после поднятия сервера.
  app.addHook('onReady', async () => {
    // Сразу один прогрев.
    await preload();
    // И дальше по таймеру.
    setInterval(() => {
      void preload();
    }, config.refreshIntervalSeconds * 1000).unref();
  });
}
