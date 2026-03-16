import { mkdir, readFile, readdir, rename, stat, unlink, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';

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

export type JsonFileCacheOptions = {
  // Логическое имя кэша (например: "coingecko" или "news")
  name: string;
  // Основной файл кэша, который постоянно перезаписывается (current).
  currentFilePath: string;
  // Каталог для дневных файлов: <name>_YYYY-MM-DD.json
  dailyDir?: string;
  // Каталог для снапшотов с датой+временем: <name>_YYYY-MM-DD_HH-mm-ss.json
  snapshotsDir?: string;
  // Сколько снапшотов хранить в рамках одной даты (по умолчанию 2).
  snapshotsPerDay?: number;
  // Сколько дней хранить дневные файлы (по умолчанию не чистим).
  dailyRetentionDays?: number;
  // Инъекция времени для тестов.
  clock?: () => number;
};

export class JsonFileCache {
  private readonly name: string;
  private readonly currentFilePath: string;
  private readonly dailyDir: string | null;
  private readonly snapshotsDir: string | null;
  private readonly snapshotsPerDay: number;
  private readonly dailyRetentionDays: number | null;
  private readonly clock: () => number;
  private readonly map = new Map<string, CacheEntry>();
  private persistTimer: NodeJS.Timeout | null = null;
  private isLoaded = false;
  private snapshotTimer: NodeJS.Timeout | null = null;

  constructor(opts: JsonFileCacheOptions) {
    this.name = opts.name;
    this.currentFilePath = opts.currentFilePath;
    this.dailyDir = opts.dailyDir ?? null;
    this.snapshotsDir = opts.snapshotsDir ?? null;
    this.snapshotsPerDay = Math.max(1, opts.snapshotsPerDay ?? 2);
    this.dailyRetentionDays =
      typeof opts.dailyRetentionDays === 'number' ? Math.max(1, opts.dailyRetentionDays) : null;
    this.clock = opts.clock ?? (() => Date.now());
  }

  async load(): Promise<void> {
    if (this.isLoaded) return;
    this.isLoaded = true;

    try {
      await this.loadFromFile(this.currentFilePath);
      return;
    } catch {
      // Нормально: файла может не быть на первом старте.
      // Если файл есть, но повреждён — попробуем подняться из дневного кэша.
      await this.tryLoadFromDailyFallback();
    }
  }

  startAutoSnapshots(intervalMs: number): void {
    if (intervalMs <= 0) return;
    if (!this.dailyDir && !this.snapshotsDir) return;
    if (this.snapshotTimer) return;

    this.snapshotTimer = setInterval(() => {
      void this.snapshotNow().catch(() => undefined);
    }, intervalMs);
    this.snapshotTimer.unref();
  }

  stopAutoSnapshots(): void {
    if (!this.snapshotTimer) return;
    clearInterval(this.snapshotTimer);
    this.snapshotTimer = null;
  }

  async snapshotNow(): Promise<void> {
    const now = this.clock();
    const persisted = this.buildPersistedPayload();
    const json = JSON.stringify(persisted);

    // 1) Дневной файл (по дате)
    if (this.dailyDir) {
      const date = formatDateUtc(now);
      const dailyPath = join(this.dailyDir, `${this.name}_${date}.json`);
      await mkdir(dirname(dailyPath), { recursive: true });
      await writeFileAtomic(dailyPath, json);
      if (this.dailyRetentionDays) {
        await this.pruneDailyFiles(this.dailyRetentionDays);
      }
    }

    // 2) Снапшот с датой+временем
    if (this.snapshotsDir) {
      const date = formatDateUtc(now);
      const time = formatTimeUtc(now);
      const dayDir = join(this.snapshotsDir, this.name, date);
      const snapshotPath = join(dayDir, `${this.name}_${date}_${time}.json`);
      await mkdir(dirname(snapshotPath), { recursive: true });
      await writeFileAtomic(snapshotPath, json);
      await this.pruneSnapshotsForDay(dayDir, this.snapshotsPerDay);
    }
  }

  async flush(): Promise<void> {
    await this.persist();
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
      void this.persist().catch(() => {
        // Не валим процесс из-за проблем с диском.
      });
    }, 500);
  }

  private async persist(): Promise<void> {
    const payload = this.buildPersistedPayload();
    await mkdir(dirname(this.currentFilePath), { recursive: true });
    // Пишем целиком: объёмы небольшие, зато просто и надёжно.
    await writeFileAtomic(this.currentFilePath, JSON.stringify(payload));
  }

  private buildPersistedPayload(): Persisted {
    const entries: Record<string, CacheEntry> = {};
    for (const [k, v] of this.map.entries()) entries[k] = v;
    return { version: 1, entries };
  }

  private async loadFromFile(path: string): Promise<void> {
    const raw = await readFile(path, 'utf8');
    const parsed = JSON.parse(raw) as Persisted;
    if (!parsed || parsed.version !== 1 || typeof parsed.entries !== 'object') return;

    for (const [k, v] of Object.entries(parsed.entries)) {
      if (!v || typeof v !== 'object') continue;
      this.map.set(k, v as CacheEntry);
    }
  }

  private async tryLoadFromDailyFallback(): Promise<void> {
    if (!this.dailyDir) return;
    try {
      const candidate = await pickLatestDailyFile(this.dailyDir, this.name);
      if (!candidate) return;
      await this.loadFromFile(candidate);
    } catch {
      // Если даже дневной кэш не читается — просто стартуем пустыми.
    }
  }

  private async pruneSnapshotsForDay(dayDir: string, keep: number): Promise<void> {
    try {
      const files = await readdir(dayDir);
      const jsonFiles = files.filter((f) => f.toLowerCase().endsWith('.json'));
      if (jsonFiles.length <= keep) return;

      const withMtime = await Promise.all(
        jsonFiles.map(async (f) => {
          const full = join(dayDir, f);
          const s = await stat(full);
          return { full, mtimeMs: s.mtimeMs };
        })
      );
      withMtime.sort((a, b) => b.mtimeMs - a.mtimeMs);
      const toDelete = withMtime.slice(keep);
      await Promise.all(toDelete.map((x) => unlink(x.full).catch(() => undefined)));
    } catch {
      // best-effort
    }
  }

  private async pruneDailyFiles(retentionDays: number): Promise<void> {
    if (!this.dailyDir) return;

    const cutoffMs = this.clock() - retentionDays * 24 * 60 * 60 * 1000;

    try {
      const files = await readdir(this.dailyDir);
      const prefix = `${this.name}_`;
      for (const f of files) {
        if (!f.startsWith(prefix) || !f.toLowerCase().endsWith('.json')) continue;
        const full = join(this.dailyDir, f);
        const s = await stat(full);
        if (s.mtimeMs < cutoffMs) {
          await unlink(full).catch(() => undefined);
        }
      }
    } catch {
      // best-effort
    }
  }
}

function formatDateUtc(ms: number): string {
  const d = new Date(ms);
  const yyyy = d.getUTCFullYear();
  const mm = String(d.getUTCMonth() + 1).padStart(2, '0');
  const dd = String(d.getUTCDate()).padStart(2, '0');
  return `${yyyy}-${mm}-${dd}`;
}

function formatTimeUtc(ms: number): string {
  const d = new Date(ms);
  const hh = String(d.getUTCHours()).padStart(2, '0');
  const mi = String(d.getUTCMinutes()).padStart(2, '0');
  const ss = String(d.getUTCSeconds()).padStart(2, '0');
  return `${hh}-${mi}-${ss}`;
}

async function writeFileAtomic(path: string, content: string): Promise<void> {
  const tmp = `${path}.tmp`;
  await writeFile(tmp, content, 'utf8');
  try {
    await rename(tmp, path);
  } catch {
    // На некоторых FS rename может фейлиться, если target уже существует.
    // В таком случае пытаемся удалить и повторить.
    await unlink(path).catch(() => undefined);
    await rename(tmp, path);
  }
}

async function pickLatestDailyFile(dailyDir: string, name: string): Promise<string | null> {
  const files = await readdir(dailyDir);
  const prefix = `${name}_`;
  const candidates = files
    .filter((f) => f.startsWith(prefix) && f.toLowerCase().endsWith('.json'))
    .map((f) => join(dailyDir, f));

  if (candidates.length === 0) return null;

  const withMtime = await Promise.all(
    candidates.map(async (full) => {
      const s = await stat(full);
      return { full, mtimeMs: s.mtimeMs };
    })
  );
  withMtime.sort((a, b) => b.mtimeMs - a.mtimeMs);
  return withMtime[0]?.full ?? null;
}
