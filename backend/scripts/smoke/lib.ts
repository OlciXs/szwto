/**
 * Mini framework do smoke testów API (bez dodatkowych zależności).
 * Każdy plik w scripts/smoke/checks/ eksportuje `checks: SmokeCheck[]`.
 */

export interface ApiResponse<T = any> {
  status: number;
  body: T;
}

export class Api {
  token: string | null = null;

  constructor(readonly baseUrl: string) {}

  async request<T = any>(
    method: string,
    path: string,
    body?: unknown,
  ): Promise<ApiResponse<T>> {
    const response = await fetch(`${this.baseUrl}${path}`, {
      method,
      headers: {
        'Content-Type': 'application/json',
        ...(this.token ? { Authorization: `Bearer ${this.token}` } : {}),
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
    const text = await response.text();
    return { status: response.status, body: text ? JSON.parse(text) : null };
  }

  get<T = any>(path: string) {
    return this.request<T>('GET', path);
  }

  post<T = any>(path: string, body?: unknown) {
    return this.request<T>('POST', path, body);
  }

  put<T = any>(path: string, body?: unknown) {
    return this.request<T>('PUT', path, body);
  }

  patch<T = any>(path: string, body?: unknown) {
    return this.request<T>('PATCH', path, body);
  }

  delete<T = any>(path: string) {
    return this.request<T>('DELETE', path);
  }
}

export interface SmokeContext {
  api: Api;
  /** Dane współdzielone między testami (np. id zabytku, dane gracza). */
  state: Record<string, any>;
}

export interface SmokeCheck {
  name: string;
  /** Zwrócony tekst jest wypisywany obok ✅ jako szczegół. */
  run: (ctx: SmokeContext) => Promise<string | void>;
}

export class SmokeError extends Error {}

export function expect(condition: unknown, message: string): asserts condition {
  if (!condition) throw new SmokeError(message);
}

export function expectStatus(res: ApiResponse, status: number) {
  expect(
    res.status === status,
    `oczekiwano HTTP ${status}, jest ${res.status}: ${JSON.stringify(res.body)?.slice(0, 300)}`,
  );
}
