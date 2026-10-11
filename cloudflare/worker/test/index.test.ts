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
    tafsirNetworkRateLimit?: FakeRateLimit;
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
    TAFSIR_NETWORK_RATE_LIMITER:
      options.tafsirNetworkRateLimit ?? new FakeRateLimit(),
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
  it("validates and stores preset feedback", async () => {
    const database = new FakeDatabase();
    const response = await worker.fetch(
      new Request("https://example.com/v1/feedback", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({
          feedback_choice: "suggestion",
          platform: "android",
          app_version: "1.0.0",
        }),
      }),
      baseEnv(database),
    );

    expect(response.status).toBe(201);
    expect(database.sql).toContain("INSERT INTO anonymous_feedback");
    expect(database.statement.values).toEqual([
      "suggestion",
      "android",
      "1.0.0",
    ]);
  });

  it("keeps network and installation identities out of stored feedback", async () => {
    const database = new FakeDatabase();
    const response = await worker.fetch(new Request("https://example.com/v1/feedback", {
      method: "POST", headers: mobileClientHeaders,
      body: JSON.stringify({feedback_choice: "suggestion", platform: "android", app_version: "1.0.0"}),
    }), baseEnv(database));
    expect(response.status).toBe(201);
    expect(database.statement.values).toEqual(["suggestion", "android", "1.0.0"]);
    expect(database.sql).not.toMatch(/client_id|ip|bookmarks/);
  });

  for (const body of [
    { feedback_text: "My name and email", platform: "android", app_version: "1.0.0" },
    { feedback_choice: "My name and email", platform: "android", app_version: "1.0.0" },
    { feedback_choice: "suggestion", feedback_text: "My name and email", platform: "android", app_version: "1.0.0" },
    { feedback_choice: "suggestion", platform: "my@email.example", app_version: "1.0.0" },
    { feedback_choice: "suggestion", platform: "android", app_version: "my@email.example" },
  ]) {
    it(`rejects free-form feedback or metadata: ${JSON.stringify(body)}`, async () => {
      const database = new FakeDatabase();
      const response = await worker.fetch(new Request("https://example.com/v1/feedback", {
        method: "POST", headers: mobileClientHeaders, body: JSON.stringify(body),
      }), baseEnv(database));
      expect(response.status).toBe(400);
      expect(database.statement.run).not.toHaveBeenCalled();
    });
  }

  for (const choice of ["reading_display", "translation_tafsir", "reminders", "app_problem", "suggestion"]) {
    it(`stores preset ${choice} without localization or personal text`, async () => {
      const database = new FakeDatabase();
      const response = await worker.fetch(new Request("https://example.com/v1/feedback", {
        method: "POST", headers: mobileClientHeaders,
        body: JSON.stringify({ feedback_choice: choice, platform: "android", app_version: "unknown" }),
      }), baseEnv(database));
      expect(response.status).toBe(201);
      expect(database.statement.values).toEqual([choice, "android", "unknown"]);
    });
  }

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
          feedback_choice: "suggestion",
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
          feedback_choice: "suggestion",
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
    const tafsirRateLimit = new FakeRateLimit();
    const tafsirNetworkRateLimit = new FakeRateLimit();
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
      tafsirRequest({ operation: "sources" }),
      baseEnv(undefined, { tafsirRateLimit, tafsirNetworkRateLimit }),
    );

    expect(response.status).toBe(200);
    expect(tafsirRateLimit.limit).toHaveBeenCalledWith({
      key: "client:0123456789abcdef0123456789abcdef",
    });
    expect(tafsirNetworkRateLimit.limit).toHaveBeenCalledWith({
      key: "network:203.0.113.10",
    });
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

  it("returns the same retry guidance when the network limit is exceeded", async () => {
    const upstreamFetch = vi.fn();
    vi.stubGlobal("fetch", upstreamFetch);
    const tafsirNetworkRateLimit = new FakeRateLimit(false);

    const response = await worker.fetch(
      tafsirRequest({ operation: "sources" }),
      baseEnv(undefined, { tafsirNetworkRateLimit }),
    );

    expect(response.status).toBe(429);
    expect(response.headers.get("retry-after")).toBe("60");
    expect(await response.json()).toEqual({
      error: "Too many requests. Please try again shortly.",
    });
    expect(upstreamFetch).not.toHaveBeenCalled();
    expect(tafsirNetworkRateLimit.limit).toHaveBeenCalledWith({
      key: "network:203.0.113.10",
    });
  });

  it("cannot bypass the network limit by rotating client identifiers", async () => {
    const tafsirRateLimit = new FakeRateLimit();
    const tafsirNetworkRateLimit = new FakeRateLimit();
    tafsirNetworkRateLimit.limit
      .mockResolvedValueOnce({ success: true })
      .mockResolvedValueOnce({ success: false });
    const env = baseEnv(undefined, {
      tafsirRateLimit,
      tafsirNetworkRateLimit,
    });

    const first = await worker.fetch(
      tafsirRequest(
        { operation: "invalid" },
        "11111111111111111111111111111111",
      ),
      env,
    );
    const second = await worker.fetch(
      tafsirRequest(
        { operation: "invalid" },
        "22222222222222222222222222222222",
      ),
      env,
    );

    expect(first.status).toBe(400);
    expect(second.status).toBe(429);
    expect(tafsirRateLimit.limit).toHaveBeenNthCalledWith(1, {
      key: "client:11111111111111111111111111111111",
    });
    expect(tafsirRateLimit.limit).toHaveBeenNthCalledWith(2, {
      key: "client:22222222222222222222222222222222",
    });
    expect(tafsirNetworkRateLimit.limit).toHaveBeenCalledTimes(2);
    expect(tafsirNetworkRateLimit.limit).toHaveBeenNthCalledWith(1, {
      key: "network:203.0.113.10",
    });
    expect(tafsirNetworkRateLimit.limit).toHaveBeenNthCalledWith(2, {
      key: "network:203.0.113.10",
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

function tafsirRequest(
  body: Record<string, unknown>,
  clientId = mobileClientHeaders["x-client-id"],
) {
  return new Request("https://example.com/v1/tafsir", {
    method: "POST",
    headers: { ...mobileClientHeaders, "x-client-id": clientId },
    body: JSON.stringify(body),
  });
}


describe("public privacy policy", () => {
  for (const [path, language, title] of [
    ["/privacy", "en", "Optional feedback"],
    ["/privacy/ar", "ar", "الملاحظات الاختيارية"],
  ]) {
    it(`serves ${language} without credentials or database access`, async () => {
      const response = await worker.fetch(new Request(`https://example.com${path}`), {} as Env);
      expect(response.status).toBe(200);
      expect(response.headers.get("content-type")).toContain("text/html");
      expect(response.headers.get("content-security-policy")).toContain("default-src 'none'");
      expect(response.headers.has("set-cookie")).toBe(false);
      expect(await response.text()).toContain(title);
    });
  }
  it("provides HEAD and rejects writes", async () => {
    const head = await worker.fetch(new Request("https://example.com/privacy", {method: "HEAD"}), {} as Env);
    expect(head.status).toBe(200);
    expect(await head.text()).toBe("");
    const post = await worker.fetch(new Request("https://example.com/privacy", {method: "POST"}), {} as Env);
    expect(post.status).toBe(405);
    expect(post.headers.get("allow")).toBe("GET, HEAD");
  });
});


describe("security response headers", () => {
  for (const [path, method] of [["/health", "GET"], ["/privacy", "GET"], ["/missing", "GET"], ["/v1/feedback", "GET"], ["/v1/feedback", "OPTIONS"]]) {
    it(`protects ${method} ${path}`, async () => {
      const response = await worker.fetch(new Request(`https://example.com${path}`, { method }), baseEnv());
      expect(response.headers.get("strict-transport-security")).toBe("max-age=31536000");
      expect(response.headers.get("x-frame-options")).toBe("DENY");
      expect(response.headers.get("x-content-type-options")).toBe("nosniff");
      expect(response.headers.get("content-security-policy")).toContain("default-src 'none'");
    });
  }
});
