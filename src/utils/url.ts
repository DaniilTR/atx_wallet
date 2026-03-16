// Нормализуем query, чтобы одинаковые запросы попадали в один ключ кэша.
export function normalizeQuery(query: Record<string, unknown>): Record<string, string> {
  const out: Record<string, string> = {};
  for (const [key, value] of Object.entries(query)) {
    if (value === undefined || value === null) continue;
    if (Array.isArray(value)) out[key] = value.join(',');
    else out[key] = String(value);
  }

  // Сортируем ключи для стабильного ключа кэша.
  return Object.fromEntries(Object.entries(out).sort(([a], [b]) => a.localeCompare(b)));
}

export function cacheKeyFrom(pathname: string, query: Record<string, unknown>): string {
  const q = normalizeQuery(query);
  const qp = new URLSearchParams(q).toString();
  return qp ? `${pathname}?${qp}` : pathname;
}
