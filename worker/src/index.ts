export interface Env {
  DB: D1Database;
}

type Entry = {
  planId: string;
  provider: string;
  displayName: string;
  window: string;
  inputTokens: number;
  outputTokens: number;
  cacheReadTokens: number;
  capturedAt: string;
};

const SITE = "https://plananalysis.ai";
const NAME_RE = /^[\p{L}\p{N} ._-]{1,40}$/u;
const PLAN_RE = /^[a-z0-9-]{2,40}$/;

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    if (request.method === "OPTIONS") return cors(new Response(null, { status: 204 }));
    if (url.pathname === "/v1/ladder" && request.method === "GET") {
      return cors(await ladder(url, env));
    }
    if (url.pathname === "/v1/ladder" && request.method === "POST") {
      return cors(await upload(request, env));
    }
    return cors(new Response("not found", { status: 404 }));
  },
};

async function ladder(url: URL, env: Env): Promise<Response> {
  const plan = url.searchParams.get("plan") ?? "";
  if (!PLAN_RE.test(plan)) return json({ error: "bad plan" }, 400);
  const window = url.searchParams.get("window") ?? "5h";
  const rows = await env.DB.prepare(
    `SELECT display_name, provider, input_tokens, output_tokens, cache_read_tokens, captured_at
     FROM submissions
     WHERE plan_id = ? AND window = ?
     ORDER BY output_tokens DESC, input_tokens DESC
     LIMIT 50`
  )
    .bind(plan, window)
    .all<{
      display_name: string;
      provider: string;
      input_tokens: number;
      output_tokens: number;
      cache_read_tokens: number;
      captured_at: string;
    }>();
  const entries = (rows.results ?? []).map((r, i) => ({
    rank: i + 1,
    displayName: r.display_name,
    provider: r.provider,
    inputTokens: r.input_tokens,
    outputTokens: r.output_tokens,
    cacheReadTokens: r.cache_read_tokens,
    capturedAt: r.captured_at,
  }));
  return json({ planId: plan, window, entries });
}

async function upload(request: Request, env: Env): Promise<Response> {
  let body: { entries?: Entry[] };
  try {
    body = await request.json();
  } catch {
    return json({ error: "bad json" }, 400);
  }
  const entries = body.entries ?? [];
  if (entries.length === 0 || entries.length > 8) return json({ error: "bad entries" }, 400);
  const now = new Date().toISOString();
  const plans: { planId: string; detailURL: string }[] = [];
  let accepted = 0;
  for (const e of entries) {
    if (!PLAN_RE.test(e.planId) || !NAME_RE.test(e.displayName)) continue;
    if (e.window !== "5h") continue;
    const id = `${e.planId}:${e.displayName}:${e.window}`;
    await env.DB.prepare(
      `INSERT INTO submissions
        (id, plan_id, provider, display_name, window, input_tokens, output_tokens, cache_read_tokens, captured_at, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
       ON CONFLICT(id) DO UPDATE SET
        provider=excluded.provider,
        input_tokens=excluded.input_tokens,
        output_tokens=excluded.output_tokens,
        cache_read_tokens=excluded.cache_read_tokens,
        captured_at=excluded.captured_at,
        created_at=excluded.created_at`
    )
      .bind(
        id,
        e.planId,
        String(e.provider ?? "").slice(0, 20),
        e.displayName,
        e.window,
        int(e.inputTokens),
        int(e.outputTokens),
        int(e.cacheReadTokens),
        String(e.capturedAt ?? now),
        now
      )
      .run();
    accepted += 1;
    plans.push({ planId: e.planId, detailURL: `${SITE}/en/plans/${e.planId}.html#ladder` });
  }
  return json({ accepted, plans });
}

function int(n: unknown): number {
  const v = Number(n);
  return Number.isFinite(v) ? Math.max(0, Math.min(1e15, Math.floor(v))) : 0;
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });
}

function cors(res: Response): Response {
  const headers = new Headers(res.headers);
  headers.set("access-control-allow-origin", "*");
  headers.set("access-control-allow-methods", "GET,POST,OPTIONS");
  headers.set("access-control-allow-headers", "content-type");
  return new Response(res.body, { status: res.status, headers });
}
