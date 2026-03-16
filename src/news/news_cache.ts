import { config } from '../config.js';
import type { JsonFileCache, CacheEntry } from '../cache/json_file_cache.js';
import { nowMs } from '../utils/time.js';
import { fetchCointelegraphRss, type CointelegraphNewsItem } from './cointelegraph_rss.js';

export type NewsCacheStatus = 'HIT' | 'MISS' | 'STALE' | 'STALE_FALLBACK';

export type CointelegraphNewsPayload = {
  source: 'cointelegraph_ru';
  fetchedAtIso: string;
  items: CointelegraphNewsItem[];
};

const KEY = 'news:cointelegraph:ru';

export class NewsService {
  private readonly cache: JsonFileCache;
  private inFlight: Promise<void> | null = null;

  constructor(cache: JsonFileCache) {
    this.cache = cache;
  }

  async getCointelegraph(limit: number): Promise<{ payload: CointelegraphNewsPayload; cacheStatus: NewsCacheStatus }> {
    const now = nowMs();
    const cached = this.cache.get(KEY);

    if (cached && now < cached.expiresAtMs) {
      return { payload: cached.value as CointelegraphNewsPayload, cacheStatus: 'HIT' };
    }

    if (cached && now < cached.staleUntilMs) {
      this.refreshInBackground(limit);
      return { payload: cached.value as CointelegraphNewsPayload, cacheStatus: 'STALE' };
    }

    try {
      const payload = await this.fetchAndCache(limit);
      return { payload, cacheStatus: 'MISS' };
    } catch (e) {
      if (cached) {
        return { payload: cached.value as CointelegraphNewsPayload, cacheStatus: 'STALE_FALLBACK' };
      }
      throw e;
    }
  }

  refreshInBackground(limit: number): void {
    if (this.inFlight) return;
    this.inFlight = this.fetchAndCache(limit)
      .then(() => undefined)
      .finally(() => {
        this.inFlight = null;
      });
  }

  async fetchAndCache(limit: number): Promise<CointelegraphNewsPayload> {
    const items = await fetchCointelegraphRss({
      timeoutMs: config.upstreamTimeoutMs,
      limit
    });

    const now = nowMs();
    const payload: CointelegraphNewsPayload = {
      source: 'cointelegraph_ru',
      fetchedAtIso: new Date(now).toISOString(),
      items
    };

    const entry: CacheEntry = {
      value: payload,
      fetchedAtMs: now,
      expiresAtMs: now + config.newsTtlSeconds * 1000,
      staleUntilMs: now + config.newsStaleSeconds * 1000
    };

    this.cache.set(KEY, entry);
    return payload;
  }
}
