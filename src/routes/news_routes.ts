import type { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';
import { z } from 'zod';
import type { NewsService } from '../news/news_cache.js';
import { config } from '../config.js';

const querySchema = z.object({
  limit: z.coerce.number().int().positive().max(50).optional()
});

function replyUpstreamError(reply: FastifyReply) {
  return reply.code(502).send({
    error: 'UPSTREAM_UNAVAILABLE',
    message: 'Источник новостей временно недоступен'
  });
}

export async function registerNewsRoutes(
  app: FastifyInstance,
  deps: { news: NewsService }
): Promise<void> {
  const refresh = async (): Promise<void> => {
    try {
      await deps.news.fetchAndCache(config.newsLimit);
      app.log.debug('Preloaded Cointelegraph RSS');
    } catch (err) {
      app.log.warn({ err }, 'Preload Cointelegraph RSS failed');
    }
  };

  // Фоновое обновление новостей раз в час (или как задано в .env)
  app.addHook('onReady', async () => {
    await refresh();
    setInterval(() => {
      try {
        void refresh();
      } catch (err) {
        app.log.warn({ err }, 'Preload Cointelegraph RSS crashed');
      }
    }, config.newsRefreshIntervalSeconds * 1000).unref();
  });

  app.get('/api/news/cointelegraph', async (
    req: FastifyRequest<{ Querystring: Record<string, unknown> }>,
    reply: FastifyReply
  ) => {
    const parsed = querySchema.safeParse(req.query);
    if (!parsed.success) {
      return reply.code(400).send({ error: 'BAD_REQUEST' });
    }

    const limit = parsed.data.limit ?? config.newsLimit;

    try {
      const result = await deps.news.getCointelegraph(limit);
      reply.header('Content-Type', 'application/json');
      reply.header('X-Cache', result.cacheStatus);
      return reply.send(result.payload);
    } catch (err) {
      app.log.warn({ err }, 'Cointelegraph RSS fetch failed');
      return replyUpstreamError(reply);
    }
  });
}
