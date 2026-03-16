import { config } from '../config.js';
import { nowMs } from '../utils/time.js';
import { cacheKeyFrom } from '../utils/url.js';
import { JsonFileCache, type CacheEntry } from '../cache/json_file_cache.js';
import { fetchJson } from './upstream.js';

export type CacheStatus = 'HIT' | 'MISS' | 'STALE' | 'STALE_FALLBACK';

export type CachedResponse = {
  statusCode: number;
  body: unknown;
  cacheStatus: CacheStatus;
};

export type CacheProvider = (pathname: string, query: Record<string, unknown>) => JsonFileCache;

export class CoinGeckoCachedClient {
  private readonly baseUrl: string;
  private readonly cacheProvider: CacheProvider;
  private readonly inFlight = new Map<string, Promise<void>>();

  constructor(opts: { baseUrl: string; cacheProvider: CacheProvider }) {
    this.baseUrl = opts.baseUrl.replace(/\/$/, '');
    this.cacheProvider = opts.cacheProvider;
  }

  keyFor(pathname: string, query: Record<string, unknown>): string {
    return cacheKeyFrom(pathname, query);
  }

  async getJson(pathname: string, query: Record<string, unknown>): Promise<CachedResponse> {
    const key = this.keyFor(pathname, query);
    const now = nowMs();
    const cache = this.cacheProvider(pathname, query);
    const cached = cache.get(key);

    if (cached && now < cached.expiresAtMs) {
      return { statusCode: 200, body: cached.value, cacheStatus: 'HIT' };
    }

    if (cached && now < cached.staleUntilMs) {
      // Отдаём stale сразу, а обновление запускаем в фоне.
      this.refreshInBackground(cache, key, pathname, query);
      return { statusCode: 200, body: cached.value, cacheStatus: 'STALE' };
    }

    try {
      const fresh = await this.fetchAndCache(cache, key, pathname, query);
      return { statusCode: 200, body: fresh, cacheStatus: 'MISS' };
    } catch (e) {
      // Если апстрим упал, но у нас есть хоть какой-то старый кэш — отдадим его.
      if (cached) {
        return { statusCode: 200, body: cached.value, cacheStatus: 'STALE_FALLBACK' };
      }
      throw e;
    }
  }

  private refreshInBackground(
    cache: JsonFileCache,
    key: string,
    pathname: string,
    query: Record<string, unknown>
  ): void {
    if (this.inFlight.has(key)) return;
    const promise = this.fetchAndCache(cache, key, pathname, query)
      .then(() => undefined)
      .catch(() => undefined)
      .finally(() => {
        this.inFlight.delete(key);
      });
    this.inFlight.set(key, promise);
  }

  async refreshNow(pathname: string, query: Record<string, unknown>): Promise<unknown> {
    const key = this.keyFor(pathname, query);
    const cache = this.cacheProvider(pathname, query);
    return this.fetchAndCache(cache, key, pathname, query);
  }

  private async fetchAndCache(
    cache: JsonFileCache,
    key: string,
    pathname: string,
    query: Record<string, unknown>
  ): Promise<unknown> {
    const url = this.buildUrl(pathname, query);
    const res = await fetchJson(url, config.upstreamTimeoutMs);

    // CoinGecko может отвечать 429/5xx — это не данные, кэшировать не будем.
    if (res.statusCode !== 200) {
      throw new Error(`Upstream CoinGecko error: ${res.statusCode}`);
    }

    const now = nowMs();
    const entry: CacheEntry = {
      value: res.body,
      fetchedAtMs: now,
      expiresAtMs: now + config.cacheTtlSeconds * 1000,
      staleUntilMs: now + config.cacheStaleSeconds * 1000
    };

    cache.set(key, entry);
    return res.body;
  }

  private buildUrl(pathname: string, query: Record<string, unknown>): string {
    const url = new URL(this.baseUrl);
    url.pathname = pathname;

    for (const [k, v] of Object.entries(query)) {
      if (v === undefined || v === null) continue;
      if (Array.isArray(v)) url.searchParams.set(k, v.join(','));
      else url.searchParams.set(k, String(v));
    }

    return url.toString();
  }
}
