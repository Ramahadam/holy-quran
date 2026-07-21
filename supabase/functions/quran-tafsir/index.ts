const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const jsonHeaders = {
  ...corsHeaders,
  "Content-Type": "application/json; charset=utf-8",
  "Cache-Control": "private, max-age=3600",
};

const authBaseUrl = Deno.env.get("QF_AUTH_BASE_URL") ??
  "https://oauth2.quran.foundation";
const apiBaseUrl = Deno.env.get("QF_API_BASE_URL") ??
  "https://apis.quran.foundation";
const clientId = Deno.env.get("QF_CLIENT_ID") ?? "";
const clientSecret = Deno.env.get("QF_CLIENT_SECRET") ?? "";

type CachedToken = { value: string; expiresAt: number };
let cachedToken: CachedToken | undefined;

class ServiceError extends Error {
  constructor(
    message: string,
    readonly status: number,
  ) {
    super(message);
  }
}

function response(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders });
}

function requireConfiguration(): void {
  if (!clientId || !clientSecret) {
    throw new ServiceError("The tafsir service is not configured.", 503);
  }

  for (const value of [authBaseUrl, apiBaseUrl]) {
    const url = new URL(value);
    if (url.protocol !== "https:") {
      throw new ServiceError("The tafsir service is not configured.", 503);
    }
  }
}

async function getAccessToken(forceRefresh = false): Promise<string> {
  requireConfiguration();
  const now = Date.now();
  if (!forceRefresh && cachedToken && cachedToken.expiresAt > now + 60_000) {
    return cachedToken.value;
  }

  const tokenResponse = await fetch(`${authBaseUrl}/oauth2/token`, {
    method: "POST",
    headers: {
      "Authorization": `Basic ${btoa(`${clientId}:${clientSecret}`)}`,
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
  if (!isRecord(payload) ||
    typeof payload.access_token !== "string" ||
    typeof payload.expires_in !== "number") {
    throw new ServiceError("The tafsir provider returned invalid data.", 502);
  }

  cachedToken = {
    value: payload.access_token,
    expiresAt: now + Math.max(payload.expires_in - 60, 60) * 1000,
  };
  return cachedToken.value;
}

async function quranFoundationGet(path: string): Promise<unknown> {
  let token = await getAccessToken();
  let upstream = await authenticatedGet(path, token);

  if (upstream.status === 401) {
    cachedToken = undefined;
    token = await getAccessToken(true);
    upstream = await authenticatedGet(path, token);
  }

  if (upstream.status === 429) {
    throw new ServiceError("Too many tafsir requests. Please try again shortly.", 429);
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

function authenticatedGet(path: string, token: string): Promise<Response> {
  return fetch(`${apiBaseUrl}${path}`, {
    headers: {
      "x-auth-token": token,
      "x-client-id": clientId,
      "Accept": "application/json",
    },
    signal: AbortSignal.timeout(15_000),
  });
}

async function getSources(): Promise<Response> {
  const payload = await quranFoundationGet(
    "/content/api/v4/resources/tafsirs?language=en",
  );
  if (!isRecord(payload) || !Array.isArray(payload.tafsirs)) {
    throw new ServiceError("The tafsir provider returned invalid data.", 502);
  }

  const sources = payload.tafsirs.map((value) => {
    if (!isRecord(value) ||
      typeof value.id !== "number" ||
      typeof value.name !== "string" ||
      typeof value.author_name !== "string" ||
      typeof value.language_name !== "string" ||
      typeof value.slug !== "string") {
      throw new ServiceError("The tafsir provider returned invalid data.", 502);
    }
    return {
      id: value.id,
      name: value.name,
      authorName: value.author_name,
      languageName: value.language_name,
      slug: value.slug,
    };
  });

  return response({ sources });
}

async function getAyahTafsir(body: Record<string, unknown>): Promise<Response> {
  const verseKey = body.verseKey;
  const resourceId = body.resourceId;
  if (typeof verseKey !== "string" ||
    !/^(?:[1-9]|[1-9][0-9]|1[01][0-4]):[1-9][0-9]{0,2}$/.test(verseKey) ||
    typeof resourceId !== "number" ||
    !Number.isInteger(resourceId) ||
    resourceId < 1 ||
    resourceId > 10_000) {
    throw new ServiceError("Invalid ayah or tafsir source.", 400);
  }

  const encodedVerseKey = encodeURIComponent(verseKey);
  const payload = await quranFoundationGet(
    `/content/api/v4/tafsirs/${resourceId}/by_ayah/${encodedVerseKey}`,
  );
  if (!isRecord(payload) ||
    !isRecord(payload.tafsir) ||
    payload.tafsir.resource_id !== resourceId ||
    typeof payload.tafsir.text !== "string") {
    throw new ServiceError("The tafsir provider returned invalid data.", 502);
  }

  return response({
    tafsir: {
      resourceId: payload.tafsir.resource_id,
      text: payload.tafsir.text,
    },
  });
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return response({ error: "Method not allowed." }, 405);
  }

  const contentLength = Number(request.headers.get("content-length") ?? "0");
  if (contentLength > 2048) {
    return response({ error: "Request is too large." }, 413);
  }

  try {
    const rawBody = await request.text();
    if (rawBody.length > 2048) {
      return response({ error: "Request is too large." }, 413);
    }
    const body: unknown = JSON.parse(rawBody);
    if (!isRecord(body)) {
      throw new ServiceError("Invalid request.", 400);
    }
    if (body.operation === "sources") {
      return await getSources();
    }
    if (body.operation === "ayah") {
      return await getAyahTafsir(body);
    }
    throw new ServiceError("Invalid operation.", 400);
  } catch (error) {
    if (error instanceof ServiceError) {
      return response({ error: error.message }, error.status);
    }
    if (error instanceof SyntaxError) {
      return response({ error: "Invalid JSON request." }, 400);
    }
    return response({ error: "Tafsir could not be loaded." }, 500);
  }
});
