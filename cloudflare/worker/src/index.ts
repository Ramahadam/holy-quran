export interface Env {
  FEEDBACK_DB: D1Database;
  QF_CLIENT_ID: string;
  QF_CLIENT_SECRET: string;
  QF_AUTH_BASE_URL?: string;
  QF_API_BASE_URL?: string;
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

const defaultAuthBaseUrl = "https://oauth2.quran.foundation";
const defaultApiBaseUrl = "https://apis.quran.foundation";

type CachedToken = {
  clientId: string;
  value: string;
  expiresAt: number;
};

let cachedToken: CachedToken | undefined;

class ServiceError extends Error {
  constructor(
    message: string,
    readonly status: number,
  ) {
    super(message);
  }
}

function jsonResponse(
  body: unknown,
  status = 200,
  cacheControl = "no-store",
): Response {
  return Response.json(body, {
    status,
    headers: {
      ...corsHeaders,
      "Cache-Control": cacheControl,
    },
  });
}

function requireHttpsUrl(value: string): string {
  const url = new URL(value);
  if (url.protocol !== "https:") {
    throw new ServiceError("The tafsir service is not configured.", 503);
  }
  return value.replace(/\/$/, "");
}

function requireTafsirConfiguration(env: Env) {
  if (!env.QF_CLIENT_ID || !env.QF_CLIENT_SECRET) {
    throw new ServiceError("The tafsir service is not configured.", 503);
  }

  return {
    authBaseUrl: requireHttpsUrl(env.QF_AUTH_BASE_URL ?? defaultAuthBaseUrl),
    apiBaseUrl: requireHttpsUrl(env.QF_API_BASE_URL ?? defaultApiBaseUrl),
  };
}

async function getAccessToken(
  env: Env,
  authBaseUrl: string,
  forceRefresh = false,
): Promise<string> {
  const now = Date.now();
  if (
    !forceRefresh &&
    cachedToken?.clientId === env.QF_CLIENT_ID &&
    cachedToken.expiresAt > now + 60_000
  ) {
    return cachedToken.value;
  }

  const tokenResponse = await fetch(`${authBaseUrl}/oauth2/token`, {
    method: "POST",
    headers: {
      Authorization: `Basic ${btoa(`${env.QF_CLIENT_ID}:${env.QF_CLIENT_SECRET}`)}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      grant_type: "client_credentials",
      scope: "content",
    }),
    signal: AbortSignal.timeout(10_000),
  });

  if (!tokenResponse.ok) {
    throw new ServiceError("The tafsir provider is unavailable.", 502);
  }

  const payload: unknown = await tokenResponse.json();
  if (
    !isRecord(payload) ||
    typeof payload.access_token !== "string" ||
    typeof payload.expires_in !== "number"
  ) {
    throw new ServiceError("The tafsir provider returned invalid data.", 502);
  }

  cachedToken = {
    clientId: env.QF_CLIENT_ID,
    value: payload.access_token,
    expiresAt: now + Math.max(payload.expires_in - 60, 60) * 1000,
  };
  return cachedToken.value;
}

async function authenticatedGet(
  env: Env,
  apiBaseUrl: string,
  path: string,
  token: string,
): Promise<Response> {
  return fetch(`${apiBaseUrl}${path}`, {
    headers: {
      "x-auth-token": token,
      "x-client-id": env.QF_CLIENT_ID,
      Accept: "application/json",
    },
    signal: AbortSignal.timeout(15_000),
  });
}

async function quranFoundationGet(env: Env, path: string): Promise<unknown> {
  const { authBaseUrl, apiBaseUrl } = requireTafsirConfiguration(env);
  let token = await getAccessToken(env, authBaseUrl);
  let upstream = await authenticatedGet(env, apiBaseUrl, path, token);

  if (upstream.status === 401) {
    cachedToken = undefined;
    token = await getAccessToken(env, authBaseUrl, true);
    upstream = await authenticatedGet(env, apiBaseUrl, path, token);
  }

  if (upstream.status === 429) {
    throw new ServiceError(
      "Too many tafsir requests. Please try again shortly.",
      429,
    );
  }
  if (!upstream.ok) {
    throw new ServiceError("The tafsir provider is unavailable.", 502);
  }

  try {
    return await upstream.json();
  } catch {
    throw new ServiceError("The tafsir provider returned invalid data.", 502);
  }
}

async function getSources(env: Env): Promise<Response> {
  const payload = await quranFoundationGet(
    env,
    "/content/api/v4/resources/tafsirs?language=en",
  );
  if (!isRecord(payload) || !Array.isArray(payload.tafsirs)) {
    throw new ServiceError("The tafsir provider returned invalid data.", 502);
  }

  const sources = payload.tafsirs.map((value) => {
    if (
      !isRecord(value) ||
      typeof value.id !== "number" ||
      typeof value.name !== "string" ||
      (value.author_name !== null && typeof value.author_name !== "string") ||
      typeof value.language_name !== "string" ||
      typeof value.slug !== "string"
    ) {
      throw new ServiceError("The tafsir provider returned invalid data.", 502);
    }
    return {
      id: value.id,
      name: value.name,
      authorName: value.author_name ?? "",
      languageName: value.language_name,
      slug: value.slug,
    };
  });

  return jsonResponse({ sources }, 200, "public, max-age=3600");
}

async function getAyahTafsir(
  env: Env,
  body: Record<string, unknown>,
): Promise<Response> {
  const verseKey = body.verseKey;
  const resourceId = body.resourceId;
  if (
    typeof verseKey !== "string" ||
    !/^(?:[1-9]|[1-9][0-9]|1[01][0-4]):[1-9][0-9]{0,2}$/.test(verseKey) ||
    typeof resourceId !== "number" ||
    !Number.isInteger(resourceId) ||
    resourceId < 1 ||
    resourceId > 10_000
  ) {
    throw new ServiceError("Invalid ayah or tafsir source.", 400);
  }

  const payload = await quranFoundationGet(
    env,
    `/content/api/v4/tafsirs/${resourceId}/by_ayah/${encodeURIComponent(verseKey)}`,
  );
  if (
    !isRecord(payload) ||
    !isRecord(payload.tafsir) ||
    payload.tafsir.resource_id !== resourceId ||
    typeof payload.tafsir.text !== "string"
  ) {
    throw new ServiceError("The tafsir provider returned invalid data.", 502);
  }

  return jsonResponse(
    {
      tafsir: {
        resourceId: payload.tafsir.resource_id,
        text: payload.tafsir.text,
      },
    },
    200,
    "public, max-age=3600",
  );
}

async function handleTafsir(request: Request, env: Env): Promise<Response> {
  if (request.method !== "POST") {
    return jsonResponse({ error: "Method not allowed." }, 405);
  }

  const body = await readJsonObject(request, 2048);
  if (body.operation === "sources") {
    return getSources(env);
  }
  if (body.operation === "ayah") {
    return getAyahTafsir(env, body);
  }
  throw new ServiceError("Invalid operation.", 400);
}

async function handleFeedback(request: Request, env: Env): Promise<Response> {
  if (request.method !== "POST") {
    return jsonResponse({ error: "Method not allowed." }, 405);
  }

  const body = await readJsonObject(request, 4096);
  const feedbackText = body.feedback_text;
  const platform = body.platform;
  const appVersion = body.app_version;

  if (
    typeof feedbackText !== "string" ||
    feedbackText.trim().length < 1 ||
    feedbackText.trim().length > 2000 ||
    typeof platform !== "string" ||
    platform.length < 1 ||
    platform.length > 32 ||
    typeof appVersion !== "string" ||
    appVersion.length < 1 ||
    appVersion.length > 64
  ) {
    throw new ServiceError("Invalid feedback.", 400);
  }

  await env.FEEDBACK_DB.prepare(
    `INSERT INTO anonymous_feedback
      (feedback_text, platform, app_version)
      VALUES (?, ?, ?)`,
  )
    .bind(feedbackText.trim(), platform, appVersion)
    .run();

  return jsonResponse({ submitted: true }, 201);
}

async function readJsonObject(
  request: Request,
  maxLength: number,
): Promise<Record<string, unknown>> {
  if (!request.headers.get("content-type")?.toLowerCase().startsWith("application/json")) {
    throw new ServiceError("Content-Type must be application/json.", 415);
  }

  const contentLength = Number(request.headers.get("content-length") ?? "0");
  if (contentLength > maxLength) {
    throw new ServiceError("Request is too large.", 413);
  }

  const rawBody = await request.text();
  if (rawBody.length > maxLength) {
    throw new ServiceError("Request is too large.", 413);
  }

  try {
    const body: unknown = JSON.parse(rawBody);
    if (!isRecord(body)) {
      throw new ServiceError("Invalid request.", 400);
    }
    return body;
  } catch (error) {
    if (error instanceof ServiceError) throw error;
    throw new ServiceError("Invalid JSON request.", 400);
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

async function fetchHandler(request: Request, env: Env): Promise<Response> {
  if (request.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  const path = new URL(request.url).pathname.replace(/\/$/, "") || "/";
  try {
    if (path === "/health" && request.method === "GET") {
      return jsonResponse({ status: "ok" });
    }
    if (path === "/v1/tafsir") {
      return await handleTafsir(request, env);
    }
    if (path === "/v1/feedback") {
      return await handleFeedback(request, env);
    }
    return jsonResponse({ error: "Not found." }, 404);
  } catch (error) {
    if (error instanceof ServiceError) {
      return jsonResponse({ error: error.message }, error.status);
    }
    return jsonResponse({ error: "The service is temporarily unavailable." }, 500);
  }
}

export default { fetch: fetchHandler } satisfies ExportedHandler<Env>;
