import { readFileSync } from "node:fs";
import { DatabaseSync } from "node:sqlite";
import { afterEach, describe, expect, it, vi } from "vitest";

import worker, { type Env } from "../src/index";

const now = Date.parse("2026-10-11T03:00:00.000Z");
const cutoff = now - 90 * 24 * 60 * 60 * 1000;
const event = { cron: "0 3 * * *", scheduledTime: now } as ScheduledController;

afterEach(() => vi.restoreAllMocks());

describe("feedback retention", () => {
  it("deletes feedback at least 90 days old, preserves newer rows, and can run twice", async () => {
    vi.spyOn(Date, "now").mockReturnValue(now);
    const database = new DatabaseSync(":memory:");
    try {
      database.exec(readFileSync(
        new URL("../migrations/0001_anonymous_feedback.sql", import.meta.url),
        "utf8",
      ));
      const insert = database.prepare(
        "INSERT INTO anonymous_feedback (feedback_text, platform, app_version, created_at) VALUES (?, 'android', '1.0', ?)",
      );
      for (const [label, time] of [
        ["old", cutoff - 1],
        ["boundary", cutoff],
        ["recent", cutoff + 1],
        ["new", now],
      ] as const) {
        insert.run(label, new Date(time).toISOString());
      }
      const env = {
        FEEDBACK_DB: {
          prepare(sql: string) {
            return {
              bind(cutoff: string) {
                return {
                  async run() {
                    database.prepare(sql).run(cutoff);
                    return { success: true };
                  },
                };
              },
            };
          },
        },
      } as unknown as Env;
      await worker.scheduled(event, env);
      const remaining = database.prepare(
        "SELECT feedback_text FROM anonymous_feedback ORDER BY id",
      ).all().map(row => row.feedback_text);
      expect(remaining).toEqual(["recent", "new"]);
      await worker.scheduled(event, env);
      expect(database.prepare("SELECT COUNT(*) AS count FROM anonymous_feedback").get()?.count).toBe(2);
    } finally {
      database.close();
    }
  });

  it("reports database failures to the scheduler", async () => {
    const error = new Error("Database unavailable");
    const env = {
      FEEDBACK_DB: { prepare: () => ({ bind: () => ({ run: () => Promise.reject(error) }) }) },
    } as unknown as Env;
    await expect(worker.scheduled(event, env)).rejects.toThrow(error);
  });
});
