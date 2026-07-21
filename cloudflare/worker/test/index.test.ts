import { afterEach, describe, expect, it, vi } from "vitest";

import worker, { type Env } from "../src/index";

class FakeStatement {
  values: unknown[] = [];

  bind(...values: unknown[]) {
    this.values = values;
    return this;
  }

  async run() {
    return { success: true };
  }
}

class FakeDatabase {
  readonly statement = new FakeStatement();
  sql?: string;

  prepare(sql: string) {
    this.sql = sql;
    return this.statement;
  }
}

const baseEnv = (database = new FakeDatabase()) =>
  ({
    FEEDBACK_DB: database,
    QF_CLIENT_ID: "client-id",
    QF_CLIENT_SECRET: "client-secret",
  }) as unknown as Env;

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
});
