import { XMLParser } from 'fast-xml-parser';
import { request } from 'undici';

export type CointelegraphNewsItem = {
  title: string;
  link: string;
  publishedAtIso: string;
  publishedAtMs: number;
  summary?: string;
};

// RSS Cointelegraph ru
const RSS_URL = 'https://ru.cointelegraph.com/rss';

async function fetchRssXml(url: string, timeoutMs: number): Promise<string> {
  let currentUrl = url;
  for (let i = 0; i < 3; i++) {
    const res = await request(currentUrl, {
    method: 'GET',
    headers: {
      // Просим XML/RSS и подставляем более "обычный" UA,
      // т.к. некоторые CDN отдают HTML заглушку по подозрительным запросам.
      Accept: 'application/rss+xml, application/xml;q=0.9, text/xml;q=0.8, */*;q=0.1',
      'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0 Safari/537.36'
    },
    headersTimeout: timeoutMs,
    bodyTimeout: timeoutMs
    });

    // Редиректы (часто бывает с ru.cointelegraph.com)
    if ([301, 302, 303, 307, 308].includes(res.statusCode)) {
      const loc = res.headers.location;
      const next = Array.isArray(loc) ? loc[0] : loc;
      if (!next) throw new Error(`RSS redirect without Location: ${res.statusCode}`);
      currentUrl = new URL(next, currentUrl).toString();
      continue;
    }

    const text = await res.body.text();
    if (res.statusCode !== 200) {
      throw new Error(`RSS fetch failed: ${res.statusCode}`);
    }
    return text;
  }

  throw new Error('RSS fetch failed: too many redirects');
}

function normalizeText(input: unknown): string {
  const s = typeof input === 'string' ? input : String(input ?? '');
  return s.replace(/\s+/g, ' ').trim();
}

function stripHtml(input: string): string {
  // MVP: убираем теги и самые частые html-сущности.
  return input
    .replace(/<[^>]*>/g, ' ')
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/\s+/g, ' ')
    .trim();
}

function parseDateToMs(input: string): number {
  const ms = Date.parse(input);
  return Number.isFinite(ms) ? ms : 0;
}

export async function fetchCointelegraphRss(opts: {
  timeoutMs: number;
  limit: number;
}): Promise<CointelegraphNewsItem[]> {
  const xml = await fetchRssXml(RSS_URL, opts.timeoutMs);

  const parser = new XMLParser({
    ignoreAttributes: true,
    // Cointelegraph RSS обычно простой: rss.channel.item[]
    parseTagValue: true,
    trimValues: true
  });

  const decoded = parser.parse(xml) as any;
  if (!decoded?.rss?.channel) {
    // Если вместо RSS пришёл HTML (защита/редирект), decoded будет типа { html: ... }
    throw new Error('Unexpected RSS format (not rss/channel)');
  }
  const items = decoded?.rss?.channel?.item;
  const list: any[] = Array.isArray(items) ? items : items ? [items] : [];

  const out: CointelegraphNewsItem[] = [];
  for (const item of list) {
    const title = normalizeText(item?.title);
    const link = normalizeText(item?.link);
    const pubDate = normalizeText(item?.pubDate);
    const description = item?.description;

    if (!title || !link) continue;

    const publishedAtMs = parseDateToMs(pubDate);
    const publishedAtIso = publishedAtMs ? new Date(publishedAtMs).toISOString() : '';

    out.push({
      title,
      link,
      publishedAtIso,
      publishedAtMs,
      summary: description ? stripHtml(normalizeText(description)) : undefined
    });
  }

  out.sort((a, b) => (b.publishedAtMs || 0) - (a.publishedAtMs || 0));
  return out.slice(0, Math.max(1, Math.min(opts.limit, 50)));
}
