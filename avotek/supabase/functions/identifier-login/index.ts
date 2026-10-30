import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function response(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return response(405, { error: "Method not allowed." });
  }

  let body: { identifier?: unknown; password?: unknown };
  try {
    body = await request.json();
  } catch {
    return response(400, { error: "Invalid request." });
  }

  const identifier =
    typeof body.identifier === "string" ? body.identifier.trim() : "";
  const password = typeof body.password === "string" ? body.password : "";
  if (
    !identifier ||
    identifier.length > 64 ||
    password.length < 6 ||
    password.length > 256 ||
    identifier.includes("@")
  ) {
    return response(400, { error: "Invalid credentials." });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (!supabaseUrl || !serviceRoleKey || !anonKey) {
    console.error("Identifier login is missing Supabase server configuration.");
    return response(500, { error: "Sign-in is temporarily unavailable." });
  }

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const auth = createClient(supabaseUrl, anonKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  let lookup = admin.from("profiles").select("email");
  if (/^AVO-?[A-Z0-9]{4,16}$/i.test(identifier)) {
    const rawClean = identifier.toUpperCase().replace(/[^A-Z0-9]/g, "");
    const rawDigits = rawClean.replace(/^AVO/, "");
    const candidate1 = `AVO${rawDigits}`;
    const candidate2 = `AVO-${rawDigits}`;
    lookup = lookup.or(`avo_id.eq.${identifier.toUpperCase()},avo_id.eq.${candidate1},avo_id.eq.${candidate2}`);
  } else if (/^[0-9+() -]{7,20}$/.test(identifier)) {
    lookup = lookup.eq("phone", identifier);
  } else if (/^[a-zA-Z0-9._-]{3,32}$/.test(identifier)) {
    lookup = lookup.eq("username", identifier.toLowerCase());
  } else {
    return response(401, { error: "Invalid credentials." });
  }

  const { data: profile, error: lookupError } = await lookup.maybeSingle();
  if (lookupError) {
    console.error("Identifier lookup failed:", lookupError.message);
    return response(500, { error: "Sign-in is temporarily unavailable." });
  }
  if (!profile?.email) {
    return response(401, { error: "Invalid credentials." });
  }

  const { data, error } = await auth.auth.signInWithPassword({
    email: profile.email,
    password,
  });
  if (error || !data.session) {
    return response(401, { error: "Invalid credentials." });
  }

  return response(200, {
    refresh_token: data.session.refresh_token,
  });
});
