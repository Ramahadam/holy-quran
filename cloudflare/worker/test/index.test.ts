import { afterEach, describe, expect, it, vi } from "vitest";

import worker, { type Env } from "../src/index";

class FakeStatement {
  values: unknown[] = [];

  bind(...values: unknown[]) {
    this.values = values;
    return this;
  }

  run = vi.fn(async () => ({ success: true }));
}

class FakeDatabase {
  readonly statement = new FakeStatement();
  sql?: string;

  prepare(sql: string) {
    this.sql = sql;
    return this.statement;
  }
}

class FakeRateLimit {
  readonly limit: ReturnType<typeof vi.fn>;

  constructor(success = true) {
    this.limit = vi.fn(async () => ({ success }));
  }
}

class FakeCache {
  readonly keys: string[] = [];
  private readonly responses = new Map<string, Response>();

  async match(request: Request) {
    return this.responses.get(request.url)?.clone();
  }

  async put(request: Request, response: Response) {
    this.keys.push(request.url);
    this.responses.set(request.url, response.clone());
  }
}

class FakeExecutionContext {
  private readonly promises: Promise<unknown>[] = [];

  waitUntil(promise: Promise<unknown>) {
    this.promises.push(promise);
  }

  async flush() {
    await Promise.all(this.promises);
  }
}

let clientSequence = 0;

function baseEnv(
  database = new FakeDatabase(),
  options: {
    tafsirRateLimit?: FakeRateLimit;
    feedbackRateLimit?: FakeRateLimit;
    feedbackNetworkRateLimit?: FakeRateLimit;
    allowedOrigins?: string;
  } = {},
) {
  clientSequence += 1;
  return {
    FEEDBACK_DB: database,
    QF_CLIENT_ID: `client-id-${clientSequence}`,
    QF_CLIENT_SECRET: "client-secret",
    TAFSIR_RATE_LIMITER: options.tafsirRateLimit ?? new FakeRateLimit(),
    FEEDBACK_RATE_LIMITER: options.feedbackRateLimit ?? new FakeRateLimit(),
    FEEDBACK_NETWORK_RATE_LIMITER:
      options.feedbackNetworkRateLimit ?? new FakeRateLimit(),
    ALLOWED_ORIGINS: options.allowedOrigins,
  } as unknown as Env;
}

const mobileClientHeaders = {
  "content-type": "application/json",
  "x-client-id": "0123456789abcdef0123456789abcdef",
  "cf-connecting-ip": "203.0.113.10",
};

function executionContext() {
  const context = new FakeExecutionContext();
  return {
    context: context as unknown as ExecutionContext,
    flush: () => context.flush(),
  };
}

afterEach(() => {
  vi.unstubAllGlobals();
});

describe("feedback", () => {
  it("validates and stores anonymous feedback", async () => {
    const database = new FakeDatabase();
    const response = await worker.fetch(
      new Request("https://example.com/v1/feedback", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({
          feedback_text: "  Helpful app  ",
          platform: "android",
          app_version: "1.0.0",
        }),
      }),
      baseEnv(database),
    );

    expect(response.status).toBe(201);
    expect(database.sql).toContain("INSERT INTO anonymous_feedback");
    expect(database.statement.values).toEqual([
      "Helpful app",
      "android",
      "1.0.0",
    ]);
  });

  it("rejects empty feedback", async () => {
    const response = await worker.fetch(
      new Request("https://example.com/v1/feedback", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({
          feedback_text: "   ",
          platform: "android",
          app_version: "1.0.0",
        }),
      }),
      baseEnv(),
    );

    expect(response.status).toBe(400);
  });

  it("returns 429 before writing when the client feedback limit is exceeded", async () => {
    const database = new FakeDatabase();
    const feedbackRateLimit = new FakeRateLimit(false);
    const response = await worker.fetch(
      new Request("https://example.com/v1/feedback", {
        method: "POST",
        headers: mobileClientHeaders,
        body: JSON.stringify({
          feedback_text: "Helpful app",
          platform: "android",
          app_version: "1.0.0",
        }),
      }),
      baseEnv(database, { feedbackRateLimit }),
    );

    expect(response.status).toBe(429);
    expect(response.headers.get("retry-after")).toBe("60");
    expect(database.statement.run).not.toHaveBeenCalled();
    expect(feedbackRateLimit.limit).toHaveBeenCalledWith({
      key: "client:0123456789abcdef0123456789abcdef",
    });
  });

  it("applies an additional network limit to feedback", async () => {
    const database = new FakeDatabase();
    const feedbackNetworkRateLimit = new FakeRateLimit(false);
    const response = await worker.fetch(
      new Request("https://example.com/v1/feedback", {
        method: "POST",
        headers: mobileClientHeaders,
        body: JSON.stringify({
          feedback_text: "Helpful app",
          platform: "android",
          app_version: "1.0.0",
        }),
      }),
      baseEnv(database, { feedbackNetworkRateLimit }),
    );

    expect(response.status).toBe(429);
    expect(database.statement.run).not.toHaveBeenCalled();
    expect(feedbackNetworkRateLimit.limit).toHaveBeenCalledWith({
      key: "network:203.0.113.10",
    });
  });
});

describe("tafsir", () => {
  it("returns normalized tafsir sources", async () => {
    const upstreamFetch = vi
      .fn()
      .mockResolvedValueOnce(
        Response.json({ access_token: "token", expires_in: 3600 }),
      )
      .mockResolvedValueOnce(
        Response.json({
          tafsirs: [
            {
              id: 169,
              name: "Tafsir Ibn Kathir",
              author_name: "Hafiz Ibn Kathir",
              language_name: "english",
              slug: "en-tafsir-ibn-kathir",
            },
            {
              id: 168,
              name: "Ma'arif al-Qur'an",
              author_name: null,
              language_name: "english",
              slug: "en-marif-ul-quran",
            },
          ],
        }),
      );
    vi.stubGlobal("fetch", upstreamFetch);

    const response = await worker.fetch(
      new Request("https://example.com/v1/tafsir", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ operation: "sources" }),
      }),
      baseEnv(),
    );

    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({
      sources: [
        {
          id: 169,
          name: "Tafsir Ibn Kathir",
          authorName: "Hafiz Ibn Kathir",
          languageName: "english",
          slug: "en-tafsir-ibn-kathir",
        },
        {
          id: 168,
          name: "Ma'arif al-Qur'an",
          authorName: "",
          languageName: "english",
          slug: "en-marif-ul-quran",
        },
      ],
    });
  });

  it("rejects malformed ayah requests before contacting upstream", async () => {
    const upstreamFetch = vi.fn();
    vi.stubGlobal("fetch", upstreamFetch);

    const response = await worker.fetch(
      new Request("https://example.com/v1/tafsir", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({
          operation: "ayah",
          verseKey: "999:1",
          resourceId: 169,
        }),
      }),
      baseEnv(),
    );

    expect(response.status).toBe(400);
    expect(upstreamFetch).not.toHaveBeenCalled();
  });

  it("returns 429 before contacting Quran Foundation", async () => {
    const upstreamFetch = vi.fn();
    vi.stubGlobal("fetch", upstreamFetch);
    const tafsirRateLimit = new FakeRateLimit(false);

    const response = await worker.fetch(
      new Request("https://example.com/v1/tafsir", {
        method: "POST",
        headers: mobileClientHeaders,
        body: JSON.stringify({ operation: "sources" }),
      }),
      baseEnv(undefined, { tafsirRateLimit }),
    );

    expect(response.status).toBe(429);
    expect(response.headers.get("retry-after")).toBe("60");
    expect(upstreamFetch).not.toHaveBeenCalled();
    expect(tafsirRateLimit.limit).toHaveBeenCalledWith({
      key: "client:0123456789abcdef0123456789abcdef",
    });
  });

  it("caches identical source requests under a deterministic GET key", async () => {
    const cache = new FakeCache();
    vi.stubGlobal("caches", { default: cache });
    const upstreamFetch = vi
      .fn()
      .mockResolvedValueOnce(
        Response.json({ access_token: "token", expires_in: 3600 }),
      )
      .mockResolvedValueOnce(
        Response.json({
          tafsirs: [
            {
              id: 169,
              name: "Tafsir Ibn Kathir",
              author_name: "Hafiz Ibn Kathir",
              language_name: "english",
              slug: "en-tafsir-ibn-kathir",
            },
          ],
        }),
      );
    vi.stubGlobal("fetch", upstreamFetch);
    const env = baseEnv();

    const firstContext = executionContext();
    const first = await worker.fetch(
      tafsirRequest({ operation: "sources" }),
      env,
      firstContext.context,
    );
    await firstContext.flush();
    const secondContext = executionContext();
    const second = await worker.fetch(
      tafsirRequest({ operation: "sources" }),
      env,
      secondContext.context,
    );

    expect(first.status).toBe(200);
    expect(second.status).toBe(200);
    expect(await second.json()).toEqual(await first.json());
    expect(upstreamFetch).toHaveBeenCalledTimes(2);
    expect(cache.keys).toEqual([
      "https://example.com/__cache/v1/tafsir/sources",
    ]);
  });

  it("caches identical ayah requests separately by source and verse", async () => {
    const cache = new FakeCache();
    vi.stubGlobal("caches", { default: cache });
    const upstreamFetch = vi
      .fn()
      .mockResolvedValueOnce(
        Response.json({ access_token: "token", expires_in: 3600 }),
      )
      .mockResolvedValueOnce(
        Response.json({
          tafsir: { resource_id: 169, text: "In the name of Allah" },
        }),
      );
    vi.stubGlobal("fetch", upstreamFetch);
    const env = baseEnv();
    const body = { operation: "ayah", verseKey: "1:1", resourceId: 169 };

    const firstContext = executionContext();
    const first = await worker.fetch(
      tafsirRequest(body),
      env,
      firstContext.context,
    );
    await firstContext.flush();
    const secondContext = executionContext();
    const second = await worker.fetch(
      tafsirRequest(body),
      env,
      secondContext.context,
    );

    expect(first.status).toBe(200);
    expect(second.status).toBe(200);
    expect(upstreamFetch).toHaveBeenCalledTimes(2);
    expect(cache.keys).toEqual([
      "https://example.com/__cache/v1/tafsir/ayah/169/1%3A1",
    ]);
  });

  it("treats a Cache API read failure as a cache miss", async () => {
    vi.stubGlobal("caches", {
      default: {
        match: vi.fn().mockRejectedValue(new Error("cache unavailable")),
        put: vi.fn().mockResolvedValue(undefined),
      },
    });
    const upstreamFetch = vi
      .fn()
      .mockResolvedValueOnce(
        Response.json({ access_token: "token", expires_in: 3600 }),
      )
      .mockResolvedValueOnce(
        Response.json({
          tafsirs: [
            {
              id: 169,
              name: "Tafsir Ibn Kathir",
              author_name: "Hafiz Ibn Kathir",
              language_name: "english",
              slug: "en-tafsir-ibn-kathir",
            },
          ],
        }),
      );
    vi.stubGlobal("fetch", upstreamFetch);

    const response = await worker.fetch(
      tafsirRequest({ operation: "sources" }),
      baseEnv(),
      executionContext().context,
    );

    expect(response.status).toBe(200);
    expect(upstreamFetch).toHaveBeenCalledTimes(2);
  });
});

describe("routing", () => {
  it("returns a health response", async () => {
    const response = await worker.fetch(
      new Request("https://example.com/health"),
      baseEnv(),
    );

    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({ status: "ok" });
  });

  it("returns 404 for unknown routes", async () => {
    const response = await worker.fetch(
      new Request("https://example.com/unknown"),
      baseEnv(),
    );

    expect(response.status).toBe(404);
  });

  it("allows only configured browser origins", async () => {
    const response = await worker.fetch(
      new Request("https://example.com/health", {
        headers: { origin: "https://quran.example" },
      }),
      baseEnv(undefined, { allowedOrigins: "https://quran.example" }),
    );

    expect(response.headers.get("access-control-allow-origin")).toBe(
      "https://quran.example",
    );
    expect(response.headers.get("vary")).toContain("Origin");
  });

  it("rejects preflight from an unconfigured browser origin", async () => {
    const response = await worker.fetch(
      new Request("https://example.com/v1/feedback", {
        method: "OPTIONS",
        headers: {
          origin: "https://untrusted.example",
          "access-control-request-method": "POST",
        },
      }),
      baseEnv(undefined, { allowedOrigins: "https://quran.example" }),
    );

    expect(response.status).toBe(403);
    expect(response.headers.has("access-control-allow-origin")).toBe(false);
  });
});

function tafsirRequest(body: Record<string, unknown>) {
  return new Request("https://example.com/v1/tafsir", {
    method: "POST",
    headers: mobileClientHeaders,
    body: JSON.stringify(body),
  });
}
