import { request } from 'undici';

export type UpstreamResult = {
  statusCode: number;
  body: unknown;
};

export async function fetchJson(url: string, timeoutMs: number): Promise<UpstreamResult> {
  const res = await request(url, {
    method: 'GET',
    headers: {
      Accept: 'application/json',
      'User-Agent': 'server_for_atx/0.1'
    },
    headersTimeout: timeoutMs,
    bodyTimeout: timeoutMs
  });

  const text = await res.body.text();
  let decoded: unknown = null;
  try {
    decoded = text ? JSON.parse(text) : null;
  } catch {
    decoded = text;
  }

  return {
    statusCode: res.statusCode,
    body: decoded
  };
}
