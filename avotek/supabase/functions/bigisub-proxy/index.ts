const corsHeadersBase = {
  "access-control-allow-headers": "authorization, apikey, content-type",
  "access-control-allow-methods": "GET, POST, OPTIONS",
  "vary": "origin",
};

const queryAllowlist: Record<string, string[]> = {
  "/api/v2/vtu/data/plans/": ["network", "plantype"],
  "/api/v2/vtu/cable/plans/": ["cable_name"],
};

const verificationAllowlist: Record<string, string[]> = {
  "/api/v2/vtu/cable/verify/": ["cable_name", "card_no"],
  "/api/v2/bills/electricity/verify/": ["company", "meter_no", "meter_type"],
};

const purchasePaths = new Set([
  "/api/v2/vtu/airtime/purchase/",
  "/api/v2/vtu/data/purchase/",
  "/api/v2/vtu/cable/purchase/",
  "/api/v2/bills/electricity/pay/",
  "/api/v2/bills/result-checker/purchase/",
]);

function jsonResponse(body: unknown, status: number, headers: Record<string, string> = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeadersBase, "content-type": "application/json", ...headers },
  });
}

function getCorsHeaders(request: Request): Record<string, string> | null {
  const origin = request.headers.get("origin");
  if (!origin) return corsHeadersBase;

  const allowedOrigins = (Deno.env.get("ALLOWED_ORIGINS") ?? "")
    .split(",")
    .map((value) => value.trim())
    .filter(Boolean);
  if (!allowedOrigins.includes(origin)) return null;

  return { ...corsHeadersBase, "access-control-allow-origin": origin };
}

async function isAuthenticated(request: Request): Promise<boolean> {
  const authorization = request.headers.get("authorization");
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (!authorization?.startsWith("Bearer ") || !supabaseUrl || !anonKey) return false;

  const response = await fetch(`${supabaseUrl.replace(/\/+$/, "")}/auth/v1/user`, {
    headers: { apikey: anonKey, authorization },
    signal: AbortSignal.timeout(8_000),
  });
  return response.ok;
}

function requestPath(url: URL): string | null {
  const marker = "/bigisub-proxy";
  const functionIndex = url.pathname.indexOf(marker);
  if (functionIndex < 0) return null;

  const path = url.pathname.slice(functionIndex + marker.length);
  return path.startsWith("/api/v2/") ? path : null;
}

function hasOnlyKeys(value: Record<string, unknown>, allowed: string[]): boolean {
  return Object.keys(value).every((key) => allowed.includes(key));
}

function validVerificationPayload(
  path: string,
  value: unknown,
): value is Record<string, unknown> {
  if (typeof value !== "object" || value === null || Array.isArray(value)) return false;
  const body = value as Record<string, unknown>;
  if (!hasOnlyKeys(body, verificationAllowlist[path])) return false;

  if (path === "/api/v2/vtu/cable/verify/") {
    return typeof body.cable_name === "string" && body.cable_name.length <= 32 &&
      typeof body.card_no === "string" && /^\d{8,16}$/.test(body.card_no);
  }

  return typeof body.company === "string" && body.company.length <= 32 &&
    typeof body.meter_no === "string" && /^[a-zA-Z0-9-]{5,32}$/.test(body.meter_no) &&
    typeof body.meter_type === "string" && ["prepaid", "postpaid"].includes(body.meter_type);
}

Deno.serve(async (request) => {
  const corsHeaders = getCorsHeaders(request);
  if (!corsHeaders) return jsonResponse({ message: "Origin is not allowed." }, 403);

  if (request.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  try {
    if (!await isAuthenticated(request)) {
      return jsonResponse({ message: "Sign in to use this service." }, 401, corsHeaders);
    }

    const url = new URL(request.url);
    const path = requestPath(url);
    if (!path) return jsonResponse({ message: "Unknown provider endpoint." }, 404, corsHeaders);

    if (purchasePaths.has(path)) {
      return jsonResponse({
        message: "Purchases are disabled until atomic wallet charging, PIN verification, and refund reconciliation are deployed.",
      }, 503, corsHeaders);
    }

    const apiToken = Deno.env.get("BIGISUB_API_TOKEN");
    if (!apiToken) {
      return jsonResponse({ message: "The service provider is not configured." }, 503, corsHeaders);
    }

    const upstreamUrl = new URL(`https://api.bigisub.ng${path}`);
    const allowedQuery = queryAllowlist[path];
    if (request.method === "GET" && allowedQuery) {
      for (const key of url.searchParams.keys()) {
        if (!allowedQuery.includes(key) || url.searchParams.getAll(key).length !== 1) {
          return jsonResponse({ message: "Invalid provider query." }, 400, corsHeaders);
        }
      }
      for (const key of allowedQuery) {
        const value = url.searchParams.get(key);
        if (value !== null) {
          if (value.length > 32) {
            return jsonResponse({ message: "Invalid provider query." }, 400, corsHeaders);
          }
          if (key === "network" && !/^[1-4]$/.test(value)) {
            return jsonResponse({ message: "Invalid network." }, 400, corsHeaders);
          }
          if (key === "plantype" && !/^[A-Z0-9_-]{1,16}$/i.test(value)) {
            return jsonResponse({ message: "Invalid plan type." }, 400, corsHeaders);
          }
          if (key === "cable_name" && !/^[A-Z0-9_-]{1,24}$/i.test(value)) {
            return jsonResponse({ message: "Invalid cable provider." }, 400, corsHeaders);
          }
          upstreamUrl.searchParams.set(key, value);
        }
      }
    } else if (request.method === "GET" && path === "/api/v2/bills/electricity/providers/") {
      if ([...url.searchParams.keys()].length > 0) {
        return jsonResponse({ message: "Invalid provider query." }, 400, corsHeaders);
      }
    } else if (request.method === "GET" && path === "/api/v2/bills/result-checker/prices/") {
      if ([...url.searchParams.keys()].length > 0) {
        return jsonResponse({ message: "Invalid provider query." }, 400, corsHeaders);
      }
    } else if (request.method === "POST" && verificationAllowlist[path]) {
      const rawBody = await request.text();
      if (rawBody.length > 8_192) {
        return jsonResponse({ message: "Request is too large." }, 413, corsHeaders);
      }

      let payload: unknown;
      try {
        payload = JSON.parse(rawBody);
      } catch {
        return jsonResponse({ message: "Invalid request body." }, 400, corsHeaders);
      }

      if (!validVerificationPayload(path, payload)) {
        return jsonResponse({ message: "Invalid verification details." }, 400, corsHeaders);
      }

      const upstream = await fetch(upstreamUrl, {
        method: "POST",
        headers: {
          "authorization": `Token ${apiToken}`,
          "content-type": "application/json",
        },
        body: JSON.stringify(payload),
        signal: AbortSignal.timeout(15_000),
      });
      const body = await upstream.text();
      if (!upstream.ok) {
        return jsonResponse({ message: "The provider could not verify these details." }, 502, corsHeaders);
      }
      return new Response(body, {
        status: upstream.status,
        headers: { ...corsHeaders, "content-type": "application/json" },
      });
    } else if (request.method !== "GET") {
      return jsonResponse({ message: "This provider operation is not enabled." }, 405, corsHeaders);
    } else if (!allowedQuery && ![
      "/api/v2/bills/electricity/providers/",
      "/api/v2/bills/result-checker/prices/",
    ].includes(path)) {
      return jsonResponse({ message: "Provider endpoint is not enabled." }, 404, corsHeaders);
    }

    const upstream = await fetch(upstreamUrl, {
      method: "GET",
      headers: { "authorization": `Token ${apiToken}` },
      signal: AbortSignal.timeout(15_000),
    });
    const body = await upstream.text();
    if (!upstream.ok) {
      return jsonResponse({ message: "The provider request failed." }, 502, corsHeaders);
    }
    return new Response(body, {
      status: upstream.status,
      headers: { ...corsHeaders, "content-type": "application/json" },
    });
  } catch (error) {
    console.error("Bigisub proxy request failed:", error);
    return jsonResponse({ message: "The service is temporarily unavailable." }, 502, corsHeaders);
  }
});
