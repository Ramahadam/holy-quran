import policy from "../../../assets/privacy/privacy_policy.json";

function escapeHtml(value: string): string {
  return value.replace(/[&<>"']/g, (character) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
  })[character]!);
}

export function privacyPolicyResponse(request: Request, arabic: boolean): Response {
  if (request.method !== "GET" && request.method !== "HEAD") {
    return new Response(null, { status: 405, headers: { Allow: "GET, HEAD" } });
  }
  const content = arabic ? policy.ar : policy.en;
  const sections = content.sections.map((section) =>
    `<section><h2>${escapeHtml(section.heading)}</h2><p>${escapeHtml(section.body)}</p></section>`,
  ).join("\n");
  const html = `<!doctype html>
<html lang="${arabic ? "ar" : "en"}" dir="${arabic ? "rtl" : "ltr"}">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Holy Quran — ${escapeHtml(content.title)}</title>
<style>body{max-width:48rem;margin:2rem auto;padding:0 1.25rem;font:1.125rem/1.7 system-ui,sans-serif;color:#202420;background:#fcf6ec}h1,h2{line-height:1.3;color:#2e7d32}h2{font-size:1.3rem;margin-top:2rem}a{color:#236228}p{overflow-wrap:anywhere}</style></head>
<body><nav aria-label="Language"><a href="/privacy" lang="en">English</a> · <a href="/privacy/ar" lang="ar">العربية</a></nav>
<main><h1>${escapeHtml(content.title)}</h1><p>${escapeHtml(content.updatedLabel)}</p>${sections}</main></body></html>`;
  return new Response(request.method === "HEAD" ? null : html, {
    headers: {
      "Content-Type": "text/html; charset=utf-8",
      "Content-Language": arabic ? "ar" : "en",
      "Cache-Control": "public, max-age=300",
      "Content-Security-Policy": "default-src 'none'; style-src 'unsafe-inline'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'",
      "Referrer-Policy": "no-referrer",
      "X-Content-Type-Options": "nosniff",
    },
  });
}
