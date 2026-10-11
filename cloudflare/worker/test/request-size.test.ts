import { describe, expect, it, vi } from "vitest";

import worker, { type Env } from "../src/index";

function env() {
  const run = vi.fn(async () => ({ success: true }));
  return {
    run,
    value: {
      FEEDBACK_DB: { prepare: () => ({ bind: () => ({ run }) }) },
      FEEDBACK_RATE_LIMITER: { limit: async () => ({ success: true }) },
      FEEDBACK_NETWORK_RATE_LIMITER: { limit: async () => ({ success: true }) },
      TAFSIR_RATE_LIMITER: { limit: async () => ({ success: true }) },
      TAFSIR_NETWORK_RATE_LIMITER: { limit: async () => ({ success: true }) },
    } as unknown as Env,
  };
}

function post(body: BodyInit, path = "/v1/feedback") {
  return new Request(`https://example.com${path}`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body,
    duplex: "half",
  } as RequestInit);
}

function feedback(text: string) {
  return JSON.stringify({ feedback_text: text, platform: "android", app_version: "1" });
}

describe("request byte limits", () => {
  it("rejects multibyte JSON over 4096 bytes without storing it", async () => {
    const database = env();
    const body = feedback("字".repeat(1500));
    expect(new TextEncoder().encode(body).byteLength).toBeGreaterThan(4096);
    const response = await worker.fetch(post(body), database.value);
    expect(response.status).toBe(413);
    expect(database.run).not.toHaveBeenCalled();
  });

  it("cancels an oversized stream before reading the remaining body", async () => {
    const database = env();
    const cancel = vi.fn();
    const pull = vi.fn((controller: ReadableStreamDefaultController<Uint8Array>) => {
      if (pull.mock.calls.length === 1) {
        controller.enqueue(new Uint8Array(4097).fill(32));
      } else {
        controller.enqueue(new Uint8Array(100).fill(32));
        controller.close();
      }
    });
    const body = new ReadableStream({ pull, cancel }, { highWaterMark: 0 });
    const response = await worker.fetch(post(body), database.value);
    expect(response.status).toBe(413);
    expect(pull).toHaveBeenCalledTimes(1);
    expect(cancel).toHaveBeenCalledTimes(1);
    expect(database.run).not.toHaveBeenCalled();
  });

  for (const [path, limit] of [["/v1/feedback", 4096], ["/v1/tafsir", 2048]] as const) {
    it(`enforces cumulative byte limits for ${path}`, async () => {
      const database = env();
      const cancel = vi.fn();
      let pulls = 0;
      const body = new ReadableStream<Uint8Array>({
        pull(controller) {
          pulls += 1;
          if (pulls <= 2) controller.enqueue(new Uint8Array(limit / 2 + 1).fill(32));
          else controller.close();
        },
        cancel,
      }, { highWaterMark: 0 });
      const response = await worker.fetch(post(body, path), database.value);
      expect(response.status).toBe(413);
      expect(pulls).toBe(2);
      expect(cancel).toHaveBeenCalledTimes(1);
      expect(database.run).not.toHaveBeenCalled();
    });
  }

  it("decodes multibyte text split between streamed chunks", async () => {
    const database = env();
    const bytes = new TextEncoder().encode(feedback("ملاحظة"));
    const split = bytes.findIndex(byte => byte >= 0xc0) + 1;
    const body = new ReadableStream<Uint8Array>({
      start(controller) {
        controller.enqueue(bytes.slice(0, split));
        controller.enqueue(bytes.slice(split));
        controller.close();
      },
    });
    const response = await worker.fetch(post(body), database.value);
    expect(response.status).toBe(201);
    expect(database.run).toHaveBeenCalledTimes(1);
  });

  it("accepts valid JSON at exactly 4096 bytes with no Content-Length", async () => {
    const database = env();
    const json = feedback("Suggestion");
    const body = json + " ".repeat(4096 - new TextEncoder().encode(json).byteLength);
    const request = post(body);
    expect(request.headers.has("content-length")).toBe(false);
    const response = await worker.fetch(request, database.value);
    expect(response.status).toBe(201);
    expect(database.run).toHaveBeenCalledTimes(1);
  });
});
