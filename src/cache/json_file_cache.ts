import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { dirname } from 'node:path';

export type CacheValue = unknown;

export type CacheEntry = {
  value: CacheValue;
  // Когда получили данные от апстрима.
  fetchedAtMs: number;
  // До какого момента считаем данные "свежими".
  expiresAtMs: number;
  // До какого момента можно отдавать данные как "stale".
  staleUntilMs: number;
};

type Persisted = {
  version: 1;
  entries: Record<string, CacheEntry>;
};

export class JsonFileCache {
  private readonly filePath: string;
  private readonly map = new Map<string, CacheEntry>();
  private persistTimer: NodeJS.Timeout | null = null;
  private isLoaded = false;

  constructor(filePath: string) {
    this.filePath = filePath;
  }

  async load(): Promise<void> {
    if (this.isLoaded) return;
    this.isLoaded = true;

    try {
      const raw = await readFile(this.filePath, 'utf8');
      const parsed = JSON.parse(raw) as Persisted;
      if (!parsed || parsed.version !== 1 || typeof parsed.entries !== 'object') return;

      for (const [k, v] of Object.entries(parsed.entries)) {
        if (!v || typeof v !== 'object') continue;
        this.map.set(k, v as CacheEntry);
      }
    } catch {
      // Нормально: файла может не быть на первом старте.
    }
  }

  get(key: string): CacheEntry | undefined {
    return this.map.get(key);
  }

  set(key: string, entry: CacheEntry): void {
    this.map.set(key, entry);
    this.schedulePersist();
  }

  private schedulePersist(): void {
    if (this.persistTimer) return;
    this.persistTimer = setTimeout(() => {
      this.persistTimer = null;
      void this.persist();
    }, 500);
  }

  private async persist(): Promise<void> {
    const entries: Record<string, CacheEntry> = {};
    for (const [k, v] of this.map.entries()) entries[k] = v;

    const payload: Persisted = { version: 1, entries };
    await mkdir(dirname(this.filePath), { recursive: true });
    // Пишем целиком: объёмы небольшие, зато просто и надёжно.
    await writeFile(this.filePath, JSON.stringify(payload), 'utf8');
  }
}
