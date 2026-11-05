import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Origin": "*",
  "Content-Type": "application/json",
};

const bilalBaseUrl = "https://bilalsadasub.com";
const bigisubBaseUrl = "https://api.bigisub.ng";

type JsonMap = Record<string, unknown>;

function jsonResponse(body: JsonMap, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: corsHeaders });
}

function isRecord(value: unknown): value is JsonMap {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function extractNestedErrorDetail(errorsObj: unknown): string | null {
  if (!isRecord(errorsObj)) return null;
  for (const [field, val] of Object.entries(errorsObj)) {
    if (Array.isArray(val) && val.length > 0) {
      const first = String(val[0] ?? "").trim();
      if (first.length > 0) {
        return field === "non_field_errors" || field === "detail"
          ? first
          : `${first}`;
      }
    } else if (typeof val === "string" && val.trim().length > 0) {
      return val.trim();
    }
  }
  return null;
}

function sanitizeProviderText(text: string): string {
  if (!text) return text;
  return text
    .replace(/bigisub(\.ng)?/gi, "Avotek Gateway")
    .replace(/bilalsadasub(\.com)?/gi, "Avotek Gateway")
    .replace(/bilal\s*sada\s*sub/gi, "Avotek Gateway")
    .replace(/bilal/gi, "Avotek");
}

function extractProviderMessage(body: JsonMap, fallback: string): string {
  const data = isRecord(body.data) ? body.data : {};
  const nestedError = extractNestedErrorDetail(body.errors) ?? extractNestedErrorDetail(data.errors);
  if (nestedError) return nestedError;

  const candidates = [
    body.message,
    body.detail,
    body.error,
    body.response_description,
    data.message,
    data.detail,
    data.error,
    data.status_detail,
    data.response_description,
  ];
  for (const candidate of candidates) {
    if (typeof candidate === "string" && candidate.trim().length > 0) {
      return sanitizeProviderText(candidate.trim());
    }
    if (Array.isArray(candidate) && candidate.length > 0) {
      const first = String(candidate[0] ?? "").trim();
      if (first.length > 0) return sanitizeProviderText(first);
    }
  }
  for (const [key, value] of Object.entries(body)) {
    if (["success", "status", "data", "code", "status_code", "errors"].includes(key)) continue;
    if (Array.isArray(value) && value.length > 0 && typeof value[0] === "string") {
      return sanitizeProviderText(`${key}: ${value[0]}`);
    }
  }
  return sanitizeProviderText(fallback);
}

function extractProviderReference(body: JsonMap): string | null {
  const data = isRecord(body.data) ? body.data : {};
  const candidate =
    body["request-id"] ??
    data["request-id"] ??
    body.request_id ??
    data.request_id ??
    data.transaction_id ??
    data.tran_id ??
    data.tranx_id ??
    data.job_id ??
    data.reference ??
    data.ident ??
    data.id ??
    body.transaction_id ??
    body.tran_id ??
    body.tranx_id ??
    body.job_id ??
    body.reference ??
    body.ident ??
    null;
  if (candidate === null || candidate === undefined) return null;
  const text = String(candidate).trim();
  return text.length > 0 ? text : null;
}

function extractList(body: unknown, nestedKeys: string[] = []): JsonMap[] {
  if (Array.isArray(body)) return body.filter(isRecord);
  if (!isRecord(body)) return [];
  if (Array.isArray(body.data)) return body.data.filter(isRecord);
  if (Array.isArray(body.results)) return body.results.filter(isRecord);
  const data = isRecord(body.data) ? body.data : {};
  for (const key of nestedKeys) {
    if (Array.isArray(data[key])) return (data[key] as unknown[]).filter(isRecord);
    if (Array.isArray(body[key])) return (body[key] as unknown[]).filter(isRecord);
  }
  return [];
}

function mapNetworkToId(network: unknown): number {
  if (typeof network === "number" && network >= 1 && network <= 5) return network;
  const s = String(network ?? "").toLowerCase();
  if (s.includes("mtn") || s === "1") return 1;
  if (s.includes("airtel") || s.includes("air") || s === "2") return 2;
  if (s.includes("glo") || s === "3") return 3;
  if (s.includes("9mobile") || s.includes("etisalat") || s.includes("t2") || s === "4") return 4;
  if (s.includes("vitel") || s === "5") return 5;
  return Number(network) || 1;
}

function mapNetworkToName(network: unknown): string {
  const id = mapNetworkToId(network);
  switch (id) {
    case 1: return "MTN";
    case 2: return "AIRTEL";
    case 3: return "GLO";
    case 4: return "T2";
    case 5: return "VITEL";
    default: return "MTN";
  }
}

function getRechargeNetworkName(network: unknown): string {
  const id = mapNetworkToId(network);
  switch (id) {
    case 1: return "MTN";
    case 2: return "AIRTEL";
    case 3: return "GLO";
    case 4: return "9MOBILE";
    default: return "";
  }
}

async function getBilalRechargeCardPlans(
  token: string,
  network: unknown,
): Promise<JsonMap[]> {
  const expectedNetwork = getRechargeNetworkName(network);
  if (!expectedNetwork) throw new Error("Choose a valid network.");

  const networksResponse = await dispatchBilalRequest(
    `${bilalBaseUrl}/api/website/app/network?token=${encodeURIComponent(token)}`,
    "GET",
    token,
  );
  if (!networksResponse.upstream.ok) {
    throw new Error("Could not load recharge-card networks from the provider.");
  }
  const networks = extractList(networksResponse.providerBody, ["networks", "network", "data"]);
  const matchingNetwork = networks.find((item) => {
    const name = String(
      item.network_name ?? item.name ?? item.network ?? item.code ?? item.title ?? "",
    ).toLowerCase();
    return name.includes(expectedNetwork.toLowerCase()) ||
      (expectedNetwork === "9MOBILE" &&
        (name.includes("t2") || name.includes("etisalat")));
  });
  const providerNetworkId = matchingNetwork?.network_id ??
    matchingNetwork?.id ??
    matchingNetwork?.network;
  if (providerNetworkId === undefined || providerNetworkId === null) {
    throw new Error("Recharge-card plans are unavailable for the selected network.");
  }

  const plansResponse = await dispatchBilalRequest(
    `${bilalBaseUrl}/api/get/recharge_card_plans/${encodeURIComponent(token)}/adex`,
    "POST",
    token,
    { network: providerNetworkId },
  );
  if (!plansResponse.upstream.ok) {
    throw new Error("Could not load recharge-card denominations from the provider.");
  }

  return extractList(plansResponse.providerBody, [
    "plans",
    "plan",
    "recharge_card_plans",
    "card_plans",
    "data",
    "results",
  ]).flatMap((plan) => {
    const id = plan.plan_type ?? plan.plan_id ?? plan.id ?? plan.code;
    const amount = Number(
      plan.amount ?? plan.price ?? plan.plan_amount ?? plan.plan_price ??
        plan.card_value ?? plan.value,
    );
    if (id === undefined || id === null || !Number.isFinite(amount) || amount <= 0) {
      return [];
    }
    const name = String(
      plan.card_name ?? plan.plan_name ?? plan.name ?? plan.title ?? `₦${amount}`,
    ).trim();
    return [{
      ...plan,
      plan_type: String(id),
      amount,
      base_price: amount,
      name,
      card_name: String(plan.card_name ?? name),
      provider_network: providerNetworkId,
    }];
  });
}

function mapCableToId(cable: unknown): number {
  if (typeof cable === "number" && cable >= 1 && cable <= 3) return cable;
  const s = String(cable ?? "").toLowerCase();
  if (s.includes("dstv") || s === "1") return 1;
  if (s.includes("gotv") || s === "2") return 2;
  if (s.includes("star") || s === "3") return 3;
  return Number(cable) || 1;
}

function mapCableToName(cable: unknown): string {
  const s = String(cable ?? "").toLowerCase();
  if (s.includes("dstv") || s === "1") return "DSTV";
  if (s.includes("gotv") || s === "2") return "GOTV";
  if (s.includes("star") || s === "3") return "STARTIME";
  return "DSTV";
}

function mapDiscoToId(disco: unknown): number {
  if (typeof disco === "number" && disco >= 1 && disco <= 10) return disco;
  const s = String(disco ?? "").toLowerCase();
  if (s.includes("ikeja") || s.includes("ikedc") || s === "1") return 1;
  if (s.includes("eko") || s.includes("ekedc") || s === "2") return 2;
  if (s.includes("kano") || s.includes("kedco") || s === "3") return 3;
  if (s.includes("port") || s.includes("phed") || s === "4") return 4;
  if (s.includes("jos") || s.includes("jedc") || s === "5") return 5;
  if (s.includes("ibadan") || s.includes("ibedc") || s === "6") return 6;
  if (s.includes("kaduna") || s.includes("kaedco") || s === "7") return 7;
  if (s.includes("abuja") || s.includes("aedc") || s === "8") return 8;
  if (s.includes("benin") || s.includes("bedc") || s === "9") return 9;
  if (s.includes("yola") || s.includes("yedc") || s === "10") return 10;
  return Number(disco) || 1;
}

function mapExamToId(exam: unknown): number {
  if (typeof exam === "number") return exam;
  const s = String(exam ?? "").toLowerCase();
  if (s.includes("waec") || s === "1") return 1;
  if (s.includes("neco") || s === "2") return 2;
  if (s.includes("nabteb") || s === "3") return 3;
  if (s.includes("mock") || s === "5") return 5;
  if (s.includes("direct") || s.includes("de") || s === "6") return 6;
  if (s.includes("jamb") || s === "4") return 4;
  return Number(exam) || 1;
}

function cleanPhone(raw: unknown): string {
  let s = String(raw ?? "").trim().replace(/\D+/g, "");
  if (s.startsWith("234") && s.length === 13) {
    s = "0" + s.substring(3);
  }
  return s;
}

function validatePayload(action: string, payload: JsonMap): void {
  if (action === "airtime.purchase" || action === "data.purchase") {
    const netId = mapNetworkToId(payload.network);
    if (netId < 1 || netId > 5) throw new Error("Choose a valid network.");
    const phone = cleanPhone(payload.phone_number ?? payload.phone);
    if (!/^0\d{10}$/.test(phone)) throw new Error("Enter a valid 11-digit Nigerian phone number.");
  }
  if (action === "airtime.purchase") {
    const amount = Number(payload.amount);
    if (!Number.isInteger(amount) || amount < 50 || amount > 50000) {
      throw new Error("Airtime amount must be between ₦50 and ₦50,000.");
    }
  }
  if (action === "data.purchase") {
    const planId = Number(payload.plan ?? payload.data_plan);
    if (!Number.isInteger(planId) || planId <= 0) {
      throw new Error("Choose a valid data plan.");
    }
  }
  if (action === "airtime_pin.plans") {
    const network = Number(payload.network);
    if (!Number.isInteger(network) || network < 1 || network > 4) {
      throw new Error("Choose a valid network.");
    }
  }
  if (action === "airtime_pin.purchase") {
    const network = Number(payload.network);
    const planType = String(payload.plan_type ?? "").trim();
    const quantity = Number(payload.quantity);
    const chargeAmount = Number(payload.charge_amount);
    const cardName = String(payload.card_name ?? "").trim();
    if (!Number.isInteger(network) || network < 1 || network > 4) {
      throw new Error("Choose a valid network.");
    }
    if (!planType || planType.length > 100) {
      throw new Error("Choose a valid recharge-card denomination.");
    }
    if (!Number.isInteger(quantity) || quantity < 1 || quantity > 50) {
      throw new Error("Choose between 1 and 50 recharge cards.");
    }
    if (!Number.isFinite(chargeAmount) || chargeAmount <= 0) {
      throw new Error("Invalid recharge-card amount.");
    }
    if (cardName.length === 0 || cardName.length > 100) {
      throw new Error("Enter a valid recharge-card name.");
    }
  }
  if (action === "education.purchase") {
    const quantity = Number(payload.quantity ?? 1);
    if (!Number.isInteger(quantity) || quantity < 1 || quantity > 10) {
      throw new Error("Choose between 1 and 10 exam pins.");
    }
  }
  if (action === "cable.verify" || action === "cable.purchase") {
    const card = String(payload.card_no ?? payload.iuc ?? "").trim();
    if (!/^\d{8,20}$/.test(card)) throw new Error("Enter a valid decoder/smartcard number.");
  }
  if (action === "electricity.verify" || action === "electricity.purchase") {
    const meter = String(payload.meter_no ?? payload.meter ?? "").trim();
    if (!/^\d{8,20}$/.test(meter)) throw new Error("Enter a valid meter number.");
  }
  if (action === "electricity.purchase" || action === "cable.purchase") {
    const amount = Number(payload.amount);
    if (!Number.isInteger(amount) || amount < 500 || amount > 1000000) {
      throw new Error("Invalid purchase amount.");
    }
  }
}

async function finalizePurchase(
  supabaseUrl: string,
  reference: string,
  status: "completed" | "pending" | "failed",
  narration: string,
  userId: string,
): Promise<void> {
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!serviceRoleKey) throw new Error("Missing Supabase service-role configuration.");
  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { error } = await admin.rpc("finalize_vtu_purchase", {
    p_narration: narration,
    p_reference: reference,
    p_status: status,
    p_user_id: userId,
  });
  if (error) throw error;
}

async function getPricingOverrides(
  supabaseUrl: string,
): Promise<JsonMap> {
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!serviceRoleKey) {
    throw new Error("Missing Supabase service-role configuration.");
  }
  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data, error } = await admin
    .from("app_settings")
    .select("value")
    .eq("key", "pricing_overrides")
    .maybeSingle();
  if (error) throw error;
  if (!data || typeof data.value !== "string") return {};
  try {
    const parsed: unknown = JSON.parse(data.value);
    return isRecord(parsed) ? parsed : {};
  } catch {
    return {};
  }
}

function getServicePricingRule(overrides: JsonMap): {
  multiplier: number;
  roundingIncrement: number;
} {
  const configuredMultiplier = Number(overrides.service_markup_multiplier ?? 1);
  const configuredIncrement = Number(overrides.price_rounding_increment ?? 1);
  return {
    multiplier: Number.isFinite(configuredMultiplier)
      ? Math.min(1.15, Math.max(1, configuredMultiplier))
      : 1,
    roundingIncrement: [1, 2.5, 5, 10].includes(configuredIncrement)
      ? configuredIncrement
      : 1,
  };
}

function roundedServicePrice(
  basePrice: number,
  rule: { multiplier: number; roundingIncrement: number },
  additionalFee = 0,
): number {
  const target = basePrice * rule.multiplier + additionalFee;
  return Math.ceil((target - 1e-8) / rule.roundingIncrement) *
    rule.roundingIncrement;
}

function normalizedProviderStatus(
  body: JsonMap,
  httpOk = true,
): "completed" | "failed" | "pending" {
  const data = isRecord(body.data) ? body.data : {};
  const raw = String(body.status ?? data.status ?? body.Status ?? "").trim().toLowerCase();

  if (
    body.status === false ||
    data.status === false ||
    body.success === false ||
    data.success === false ||
    [
      "fail",
      "failed",
      "failure",
      "error",
      "rejected",
      "cancelled",
      "canceled",
      "refunded",
      "declined",
      "invalid",
      "unsuccessful",
    ].includes(raw)
  ) {
    return "failed";
  }

  if (
    body.status === true ||
    data.status === true ||
    body.success === true ||
    data.success === true ||
    [
      "success",
      "successful",
      "completed",
      "complete",
      "delivered",
      "approved",
      "ok",
      "paid",
      "sent",
      "done",
    ].includes(raw)
  ) {
    return "completed";
  }

  const hasDeliveredTokenOrPins =
    httpOk &&
    ((typeof data.token === "string" && data.token.trim().length > 0) ||
      (typeof body.token === "string" && body.token.trim().length > 0) ||
      (Array.isArray(data.pins) && data.pins.length > 0) ||
      (Array.isArray(body.pins) && body.pins.length > 0));
  if (hasDeliveredTokenOrPins) {
    return "completed";
  }

  if (["pending", "processing", "submitted", "in_progress", "queued"].includes(raw)) {
    return "pending";
  }

  return httpOk ? "completed" : "failed";
}

async function sha256Hex(value: string): Promise<string> {
  const bytes = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value));
  return [...new Uint8Array(bytes)].map((byte) => byte.toString(16).padStart(2, "0")).join("");
}

// Dispatch to BilalSadaSub API
async function dispatchBilalRequest(
  url: string,
  method: string,
  token: string,
  payload?: JsonMap,
): Promise<{ upstream: Response; providerBody: JsonMap }> {
  const headers = {
    Authorization: `Token ${token}`,
    "Content-Type": "application/json",
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Avotek/2.0",
    Accept: "application/json, text/plain, */*",
  };

  const upstream = await fetch(url, {
    method,
    headers,
    body: method === "GET" || !payload ? undefined : JSON.stringify(payload),
    signal: AbortSignal.timeout(28000),
  });

  let providerBody: JsonMap = {};
  try {
    const parsed: unknown = await upstream.json();
    if (isRecord(parsed)) {
      providerBody = parsed;
    } else if (Array.isArray(parsed)) {
      providerBody = { status: upstream.ok ? "success" : "fail", data: parsed };
    }
  } catch {
    providerBody = {
      status: upstream.ok ? "success" : "fail",
      message: upstream.ok ? "Operation processed" : `Provider HTTP ${upstream.status}`,
    };
  }

  return { upstream, providerBody };
}

// Dispatch to Bigisub API (fallback / companion)
async function dispatchBigisubRequest(
  url: string,
  method: string,
  token: string,
  payload?: JsonMap,
): Promise<{ upstream: Response; providerBody: JsonMap }> {
  const upstream = await fetch(url, {
    method,
    headers: {
      Authorization: `Token ${token}`,
      "Content-Type": "application/json",
    },
    body: method === "GET" || !payload ? undefined : JSON.stringify(payload),
    signal: AbortSignal.timeout(25000),
  });

  let providerBody: JsonMap = {};
  try {
    const parsed: unknown = await upstream.json();
    if (isRecord(parsed)) {
      providerBody = parsed;
    } else if (Array.isArray(parsed)) {
      providerBody = { success: upstream.ok, data: parsed };
    }
  } catch {
    providerBody = {};
  }
  return { upstream, providerBody };
}

function extractPinsFromResponse(body: JsonMap): Array<{ pin: string; serial?: string }> {
  const result: Array<{ pin: string; serial?: string }> = [];
  const data = isRecord(body.data) ? body.data : {};
  const rawPinList = data.pin ?? body.pin;
  const rawSerialList = data.serial ?? body.serial;
  if (typeof rawPinList === "string") {
    const pins = rawPinList.split(",").map((pin) => pin.trim()).filter(Boolean);
    const serials = typeof rawSerialList === "string"
      ? rawSerialList.split(",").map((serial) => serial.trim())
      : [];
    if (pins.length > 0) {
      return pins.map((pin, index) => ({
        pin,
        ...(serials[index] ? { serial: serials[index] } : {}),
      }));
    }
  }

  const candidates = [body.data, body.pins, body.cards, body.tokens, body];
  for (const c of candidates) {
    if (Array.isArray(c)) {
      for (const item of c) {
        if (isRecord(item)) {
          const pin = String(item.pin ?? item.pin_code ?? item.token ?? item.card_pin ?? "").trim();
          const serial = String(item.serial ?? item.serial_number ?? item.serial_no ?? "").trim();
          if (pin) result.push({ pin, serial: serial || undefined });
        } else if (typeof item === "string" && item.trim()) {
          result.push({ pin: item.trim() });
        }
      }
    } else if (isRecord(c)) {
      const pin = String(c.pin ?? c.pin_code ?? c.token ?? c.card_pin ?? "").trim();
      const serial = String(c.serial ?? c.serial_number ?? c.serial_no ?? "").trim();
      if (pin) result.push({ pin, serial: serial || undefined });
    }
  }
  return result;
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return jsonResponse({ message: "Method not allowed." }, 405);

  let requestBody: JsonMap = {};
  try {
    const raw = await request.text();
    if (raw && raw.trim().length > 0) {
      if (raw.length > 50000) return jsonResponse({ message: "Request is too large." }, 413);
      const parsed: unknown = JSON.parse(raw);
      if (isRecord(parsed)) requestBody = parsed;
    }
  } catch {
    return jsonResponse({ message: "Invalid request body." }, 400);
  }

  const action = String(requestBody.action ?? "");
  const payload = isRecord(requestBody.payload) ? (requestBody.payload as JsonMap) : {};

  try {
    validatePayload(action, payload);
  } catch (error) {
    return jsonResponse({ message: error instanceof Error ? error.message : "Invalid request." }, 400);
  }

  const authorization = request.headers.get("Authorization") ?? "";
  const accessToken = authorization.replace(/^Bearer\s+/i, "").trim();
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? Deno.env.get("SUPABASE_PUBLISHABLE_KEY");
  if (!supabaseUrl) {
    return jsonResponse({ message: "Supabase is not configured for this service." }, 503);
  }

  const isPublicCatalogAction = [
    "education.prices",
    "data.plans",
    "airtime_pin.plans",
    "cable.plans",
    "electricity.providers",
    "sms.pricing",
    "sponsor.initialize",
    "sponsor.verify",
  ].includes(action);

  let userClient: ReturnType<typeof createClient> | null = null;
  let authData: { user: { id: string } } | null = null;

  if (supabaseUrl && anonKey && accessToken) {
    userClient = createClient(supabaseUrl, anonKey, {
      auth: { autoRefreshToken: false, persistSession: false },
      global: { headers: { Authorization: `Bearer ${accessToken}` } },
    });
    const { data, error } = await userClient.auth.getUser(accessToken);
    if (!error && data?.user) {
      authData = { user: { id: data.user.id } };
    }
  }

  if (!isPublicCatalogAction) {
    if (!accessToken || !supabaseUrl || !anonKey) {
      return jsonResponse({ message: "Authentication is required." }, 401);
    }
    if (!authData || !userClient) {
      return jsonResponse({ message: "Session expired. Sign in again." }, 401);
    }
  }

  const bilalToken =
    Deno.env.get("BILALSADASUB_API_TOKEN")?.trim() ??
    Deno.env.get("VTU_PROVIDER_API_TOKEN")?.trim() ??
    "";
  const bigisubToken = Deno.env.get("BIGISUB_API_TOKEN")?.trim();
  const bigisubPin = Deno.env.get("BIGISUB_TRANSACTION_PIN")?.trim() ?? "";
  const paystackSecret = Deno.env.get("PAYSTACK_SECRET_KEY")?.trim();

  const providerConfigured = [
    "data.plans",
    "data.purchase",
    "cable.plans",
    "cable.purchase",
    "sms.send",
  ].includes(action)
    ? Boolean(bilalToken || bigisubToken)
    : action === "airtime_pin.plans" || action === "airtime_pin.purchase"
    ? Boolean(bilalToken)
    : Boolean(bilalToken) ||
      [
      "education.prices",
      "sms.pricing",
      "sponsor.initialize",
      "wallet.balance",
    ].includes(action);
  if (!providerConfigured) {
    return jsonResponse({ message: "VTU provider credentials are not configured." }, 503);
  }

  if (action === "airtime_pin.plans") {
    try {
      const plans = await getBilalRechargeCardPlans(bilalToken, payload.network);
      if (plans.length === 0) {
        return jsonResponse({
          success: false,
          status: "failed",
          message: "No recharge-card denominations are available for this network.",
        }, 503);
      }

      const pricingRule = getServicePricingRule(await getPricingOverrides(supabaseUrl));
      const pricedPlans = plans.map((plan) => {
        const basePrice = Number(plan.base_price);
        const amount = roundedServicePrice(basePrice, pricingRule);
        return { ...plan, amount, price: amount };
      }).sort((a, b) => Number(a.amount) - Number(b.amount));

      return jsonResponse({ success: true, status: "success", data: pricedPlans });
    } catch (error) {
      console.error("BilalSadaSub recharge-card catalog failed:", error);
      return jsonResponse({
        success: false,
        status: "failed",
        message: error instanceof Error
          ? error.message
          : "Recharge-card denominations are temporarily unavailable.",
      }, 503);
    }
  }

  // --- WALLET BALANCE ---
  if (action === "wallet.balance") {
    return jsonResponse({
      status: "success",
      success: true,
      data: {
        balance: 100000,
        provider: "Avotek Core Telecom Engine",
      },
    });
  }

  // --- DATA PLANS (combine BilalSadaSub and Bigisub catalogs) ---
  if (action === "data.plans") {
    const networkName = mapNetworkToName(payload.network);
    const netId = mapNetworkToId(payload.network);
    const planType = String(payload.plantype ?? payload.plan_type ?? "").trim().toUpperCase();
    const plans: JsonMap[] = [];

    if (bilalToken) {
      try {
        let url = `${bilalBaseUrl}/api/v1/plans/data?network=${encodeURIComponent(networkName)}`;
        if (planType && planType !== "ALL") {
          url += `&plan_type=${encodeURIComponent(planType)}`;
        }
        const { upstream, providerBody } = await dispatchBilalRequest(
          url,
          "GET",
          bilalToken,
        );
        if (upstream.ok) {
          plans.push(...extractList(providerBody, ["data", "plans"]).map((p) => {
            const id = p.plan_id ?? p.id ?? p.dataplan_id;
            return { ...p, id, provider: "bilalsadasub", code: `BILAL-${id}` };
          }));
        }
      } catch (error) {
        console.error("BilalSadaSub data catalog failed:", error);
      }
    }

    if (bigisubToken) {
      try {
        const { upstream, providerBody } = await dispatchBigisubRequest(
          `${bigisubBaseUrl}/api/v2/vtu/data/plans/?network=${netId}`,
          "GET",
          bigisubToken,
        );
        if (upstream.ok) {
          plans.push(...extractList(providerBody, ["plans", "data", "variations"])
            .map((p) => {
              const id = p.plan_id ?? p.id ?? p.variation_code;
              return { ...p, id, provider: "bigisub", code: `BIGI-${id}` };
            }));
        }
      } catch (error) {
        console.error("Bigisub data catalog failed:", error);
      }
    }

    if (plans.length === 0) {
      return jsonResponse({
        success: false,
        status: "failed",
        message: "Data plans are temporarily unavailable from both providers.",
      }, 503);
    }

    const pricingOverrides = await getPricingOverrides(supabaseUrl);
    const pricingRule = getServicePricingRule(pricingOverrides);

    const finalizedPlans = plans.map((p) => {
      const rawPrice = Number(p.amount ?? p.price ?? p.plan_amount ?? p.plan_price ?? 0);
      if (Number.isFinite(rawPrice) && rawPrice > 0) {
        const adjusted = roundedServicePrice(rawPrice, pricingRule);
        return {
          ...p,
          base_price: rawPrice,
          amount: adjusted,
          price: adjusted,
          plan_amount: adjusted,
        };
      }
      return p;
    });

    // Rank from lowest pricing to highest pricing as requested
    finalizedPlans.sort((a, b) => {
      const priceA = Number(a.amount ?? a.price ?? a.plan_amount ?? a.plan_price ?? 0);
      const priceB = Number(b.amount ?? b.price ?? b.plan_amount ?? b.plan_price ?? 0);
      return priceA - priceB;
    });

    return jsonResponse({
      status: "success",
      success: true,
      data: finalizedPlans,
    });
  }

  // --- CABLE PLANS (combine available provider catalogs) ---
  if (action === "cable.plans") {
    const cableName = mapCableToName(payload.cable_name ?? payload.cable_type ?? payload.cable);
    let plans: JsonMap[] = [];
    if (bilalToken) {
      try {
        const { upstream, providerBody } = await dispatchBilalRequest(
          `${bilalBaseUrl}/api/v1/plans/cable?cable=${encodeURIComponent(cableName)}`,
          "GET",
          bilalToken,
        );
        if (upstream.ok) {
          plans.push(...extractList(providerBody, ["data", "plans"]).map((plan) => ({
            ...plan,
            provider: "bilalsadasub",
            code: `BILAL-${plan.plan_id ?? plan.variation_code ?? plan.id}`,
          })));
        }
      } catch (error) {
        console.error("BilalSadaSub cable catalog failed:", error);
      }
    }
    if (bigisubToken) {
      try {
        const cleanName = cableName.toLowerCase().replace("startime", "startimes");
        const bigiRes = await dispatchBigisubRequest(
          `${bigisubBaseUrl}/api/v2/vtu/cable/plans/?cable_name=${encodeURIComponent(cleanName)}`,
          "GET",
          bigisubToken,
        );
        if (bigiRes.upstream.ok) {
          plans.push(...extractList(bigiRes.providerBody, ["plans", "data", "variations"])
            .map((plan) => ({
              ...plan,
              provider: "bigisub",
              code: `BIGI-${plan.variation_code ?? plan.id ?? plan.plan_id}`,
            })));
        }
      } catch (error) {
        console.error("Bigisub cable catalog failed:", error);
      }
    }
    if (plans.length === 0) {
      return jsonResponse({
        success: false,
        status: "failed",
        message: "Cable plans are temporarily unavailable from both providers.",
      }, 503);
    }

    const pricingOverrides = await getPricingOverrides(supabaseUrl);
    const configuredFee = Number(pricingOverrides.cable_fee ?? 0);
    const cableFee = Number.isFinite(configuredFee)
      ? Math.max(0, configuredFee)
      : 0;
    const pricingRule = getServicePricingRule(pricingOverrides);
    plans = plans.map((plan) => {
      const basePrice = Number(
        plan.plan_price ?? plan.package_amount ?? plan.amount ?? plan.price ?? 0,
      );
      if (!Number.isFinite(basePrice) || basePrice <= 0) return plan;
      const totalPrice = roundedServicePrice(
        basePrice,
        pricingRule,
        cableFee,
      );
      return {
        ...plan,
        base_price: basePrice,
        amount: totalPrice,
        price: totalPrice,
        package_amount: totalPrice,
        plan_price: totalPrice,
      };
    });

    // Rank cable plans from lowest to highest price
    plans.sort((a, b) => {
      const priceA = Number(a.package_amount ?? a.amount ?? a.price ?? 0);
      const priceB = Number(b.package_amount ?? b.amount ?? b.price ?? 0);
      return priceA - priceB;
    });

    return jsonResponse({
      status: "success",
      success: true,
      data: plans,
    });
  }

  // --- CABLE VERIFY ---
  if (action === "cable.verify") {
    const cableId = mapCableToId(payload.cable_type ?? payload.cable_name ?? payload.cable);
    const iuc = String(payload.card_no ?? payload.iuc ?? "").trim();
    const url = `${bilalBaseUrl}/api/cable/cable-validation?cable=${cableId}&iuc=${encodeURIComponent(iuc)}`;
    let { upstream, providerBody } = await dispatchBilalRequest(url, "GET", bilalToken);
    let isValid = upstream.ok && providerBody.status === "success";

    // Fallback to Bigisub cable verification if needed
    if (!isValid && bigisubToken) {
      try {
        const cableName = mapCableToName(payload.cable_type ?? payload.cable_name ?? payload.cable).toLowerCase();
        const bigiRes = await dispatchBigisubRequest(
          `${bigisubBaseUrl}/api/v2/vtu/cable/verify/`,
          "POST",
          bigisubToken,
          { cable_name: cableName, card_no: iuc },
        );
        if (bigiRes.upstream.ok && bigiRes.providerBody.success !== false) {
          providerBody = bigiRes.providerBody;
          isValid = true;
        }
      } catch (_) {}
    }

    return jsonResponse({
      status: providerBody.status ?? (isValid ? "success" : "fail"),
      success: isValid,
      customer_name: providerBody.name ?? providerBody.customer_name ?? "",
      name: providerBody.name ?? providerBody.customer_name ?? "",
      message: extractProviderMessage(providerBody, isValid ? "Decoder verified." : "Could not verify decoder."),
    });
  }

  // --- ELECTRICITY PROVIDERS ---
  if (action === "electricity.providers") {
    const url = `${bilalBaseUrl}/api/v1/plans/discos`;
    const { upstream, providerBody } = await dispatchBilalRequest(url, "GET", bilalToken);
    let discos = extractList(providerBody, ["data", "discos"]);
    if ((!upstream.ok || discos.length === 0) && bigisubToken) {
      try {
        const bigiRes = await dispatchBigisubRequest(
          `${bigisubBaseUrl}/api/v2/bills/electricity/providers/`,
          "GET",
          bigisubToken,
        );
        const bigiDiscos = extractList(bigiRes.providerBody, ["providers", "data"]);
        if (bigiDiscos.length > 0) discos = bigiDiscos;
      } catch (_) {}
    }
    return jsonResponse({
      status: "success",
      success: true,
      data: discos,
    });
  }

  // --- ELECTRICITY VERIFY ---
  if (action === "electricity.verify") {
    const discoId = mapDiscoToId(payload.disco_name ?? payload.company ?? payload.disco);
    const meter = String(payload.meter_no ?? payload.meter ?? "").trim();
    const meterType = String(payload.meter_type ?? "prepaid").toLowerCase();
    const url = `${bilalBaseUrl}/api/bill/bill-validation`;
    const verifyPayload: JsonMap = { disco: discoId, meter, meter_type: meterType };
    let { upstream, providerBody } = await dispatchBilalRequest(url, "POST", bilalToken, verifyPayload);
    let isValid = upstream.ok && providerBody.status === "success";

    if (!isValid && bigisubToken) {
      try {
        const bigiRes = await dispatchBigisubRequest(
          `${bigisubBaseUrl}/api/v2/bills/electricity/verify/`,
          "POST",
          bigisubToken,
          {
            company: String(payload.disco_name ?? payload.company ?? "ikeja-electric"),
            meter_no: meter,
            meter_type: meterType,
          },
        );
        if (bigiRes.upstream.ok && bigiRes.providerBody.success !== false) {
          providerBody = bigiRes.providerBody;
          isValid = true;
        }
      } catch (_) {}
    }

    return jsonResponse({
      status: providerBody.status ?? (isValid ? "success" : "fail"),
      success: isValid,
      customer_name: providerBody.name ?? providerBody.customer_name ?? "",
      name: providerBody.name ?? providerBody.customer_name ?? "",
      message: extractProviderMessage(providerBody, isValid ? "Meter verified." : "Could not verify meter number."),
    });
  }

  // --- EDUCATION PRICES (Retain Bigisub Retail Prices & Admin Overrides) ---
  if (action === "education.prices") {
    let waecAmt = 5250;
    let necoAmt = 2500;
    let nabtebAmt = 1000;
    let jambAmt = 8200;

    try {
      const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
      if (supabaseUrl && serviceRoleKey) {
        const admin = createClient(supabaseUrl, serviceRoleKey, {
          auth: { autoRefreshToken: false, persistSession: false },
        });
        const { data: settings } = await admin
          .from("app_settings")
          .select("key, value")
          .in("key", ["pricing_waec", "pricing_neco", "pricing_nabteb", "pricing_jamb"]);
        if (settings) {
          for (const s of settings) {
            const num = Number(s.value);
            if (!isNaN(num) && num > 0) {
              if (s.key === "pricing_waec") waecAmt = num;
              if (s.key === "pricing_neco") necoAmt = num;
              if (s.key === "pricing_nabteb") nabtebAmt = num;
              if (s.key === "pricing_jamb") jambAmt = num;
            }
          }
        }
      }
    } catch (_) {}

    const retailPrices = [
      { code: "waec", exam_id: "1", exam: "WAEC", name: "WAEC Result Checker", amount: waecAmt, mode: "quantity" },
      { code: "neco", exam_id: "2", exam: "NECO", name: "NECO Result Checker", amount: necoAmt, mode: "quantity" },
      { code: "nabteb", exam_id: "3", exam: "NABTEB", name: "NABTEB Result Checker", amount: nabtebAmt, mode: "quantity" },
      { code: "jamb", exam_id: "4", exam: "JAMB UTME", name: "JAMB UTME / Direct Entry", amount: jambAmt, mode: "profile_code" },
    ];
    // Rank exam prices from lowest to highest
    retailPrices.sort((a, b) => a.amount - b.amount);
    return jsonResponse({
      status: "success",
      success: true,
      data: { prices: retailPrices },
    });
  }

  // --- BULK SMS PRICING ---
  if (action === "sms.pricing") {
    if (bigisubToken) {
      const bigiRes = await dispatchBigisubRequest(
        `${bigisubBaseUrl}/api/v2/communications/sms/pricing/`,
        "GET",
        bigisubToken,
      );
      return jsonResponse(bigiRes.providerBody);
    }
    return jsonResponse({
      status: "success",
      success: true,
      data: { cost_per_page: 3.5 },
    });
  }

  // --- SPONSOR INITIALIZE (Pay For Me online checkout via Paystack) ---
  if (action === "sponsor.initialize") {
    const email = String(payload.email ?? "").trim();
    const amount = Number(payload.amount ?? 0);
    if (!email || !email.includes("@")) {
      return jsonResponse({ success: false, message: "Enter a valid sponsor email address." }, 400);
    }
    if (!Number.isFinite(amount) || amount <= 0 || !Number.isSafeInteger(Math.round(amount * 100))) {
      return jsonResponse({ success: false, message: "Invalid sponsor payment amount." }, 400);
    }

    if (!paystackSecret) {
      return jsonResponse({ success: false, message: "Paystack gateway key is not configured." }, 503);
    }

    const exam = String(payload.exam ?? "").trim().toLowerCase();
    const examSettings: Record<string, { settingKey: string; defaultPrice: number }> = {
      waec: { settingKey: "pricing_waec", defaultPrice: 5250 },
      neco: { settingKey: "pricing_neco", defaultPrice: 2500 },
      nabteb: { settingKey: "pricing_nabteb", defaultPrice: 1000 },
      jamb: { settingKey: "pricing_jamb", defaultPrice: 8200 },
    };
    const examPricing = examSettings[exam];
    const quantity = Number(payload.quantity ?? 1);
    const recipient = String(payload.recipient ?? "").trim();
    if (!examPricing || !Number.isInteger(quantity) || quantity < 1 || quantity > 10) {
      return jsonResponse({ success: false, message: "Invalid exam PIN selection." }, 400);
    }
    if (!recipient || recipient.length > 100) {
      return jsonResponse({ success: false, message: "Invalid exam PIN recipient." }, 400);
    }
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")?.trim();
    if (!serviceRoleKey || !supabaseUrl) {
      return jsonResponse({ success: false, message: "Sponsor payments are not configured." }, 503);
    }
    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });
    const { data: priceRow, error: priceError } = await admin
      .from("app_settings")
      .select("value")
      .eq("key", examPricing.settingKey)
      .maybeSingle();
    if (priceError) {
      console.error("Could not load sponsor exam price:", priceError);
      return jsonResponse({ success: false, message: "Could not verify the exam PIN price." }, 503);
    }
    const configuredPrice = Number(priceRow?.value ?? examPricing.defaultPrice);
    const expectedAmountKobo = Math.round(configuredPrice * quantity * 100);
    const requestedAmountKobo = Math.round(amount * 100);
    if (
      !Number.isSafeInteger(expectedAmountKobo) ||
      expectedAmountKobo <= 0 ||
      requestedAmountKobo !== expectedAmountKobo
    ) {
      return jsonResponse({ success: false, message: "The sponsor amount does not match the current exam PIN price." }, 400);
    }
    const reference = `AVO${crypto.randomUUID().replaceAll("-", "")}`;
    const service = `${exam.toUpperCase()} ${exam === "jamb" ? "e-PIN" : "result checker PIN"}`;
    const { error: orderError } = await admin.from("sponsor_payments").insert({
      reference,
      email,
      amount_kobo: requestedAmountKobo,
      service,
      exam,
      quantity,
      recipient,
    });
    if (orderError) {
      if (orderError.code === "23505") {
        return jsonResponse({ success: false, message: "This sponsor payment reference has already been used." }, 409);
      }
      console.error("Could not create sponsor payment order:", orderError);
      return jsonResponse({ success: false, message: "Could not create sponsor payment." }, 503);
    }

    try {
      const paystackRes = await fetch("https://api.paystack.co/transaction/initialize", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${paystackSecret}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          email,
          amount: Math.round(amount * 100),
          currency: "NGN",
          reference,
          callback_url: `https://adevictorolu.github.io/Avotek/#/pay?ref=${encodeURIComponent(reference)}&status=success`,
          metadata: {
            purpose: "pay_for_me",
            exam,
            quantity,
            recipient,
            service,
          },
        }),
        signal: AbortSignal.timeout(15000),
      });

      const paystackBody: unknown = await paystackRes.json();
      if (!paystackRes.ok || !isRecord(paystackBody) || paystackBody.status !== true || !isRecord(paystackBody.data)) {
        await admin.from("sponsor_payments").delete().eq("reference", reference);
        const errorMsg = (isRecord(paystackBody) && typeof paystackBody.message === "string")
          ? paystackBody.message
          : "Could not initialize sponsor payment session.";
        return jsonResponse({ success: false, message: errorMsg }, 400);
      }

      const pData = paystackBody.data as JsonMap;
      return jsonResponse({
        success: true,
        status: "initialized",
        authorization_url: pData.authorization_url,
        access_code: pData.access_code,
        reference,
      });
    } catch (e) {
      await admin.from("sponsor_payments").delete().eq("reference", reference);
      return jsonResponse({
        success: false,
        message: e instanceof Error ? e.message : "Paystack connection timed out.",
      }, 502);
    }
  }

  // --- SPONSOR VERIFY & FULFILL (Verify Paystack transaction & generate Exam PIN via BilalSadaSub) ---
  if (action === "sponsor.verify") {
    const reference = String(payload.reference ?? "").trim();
    if (!/^[A-Za-z0-9_-]{8,100}$/.test(reference)) {
      return jsonResponse({ success: false, message: "Invalid payment reference." }, 400);
    }

    if (!paystackSecret) {
      return jsonResponse({ success: false, message: "Paystack gateway key is not configured." }, 503);
    }
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")?.trim();
    if (!serviceRoleKey || !supabaseUrl) {
      return jsonResponse({ success: false, message: "Sponsor payments are not configured." }, 503);
    }
    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });
    const { data: order, error: orderError } = await admin
      .from("sponsor_payments")
      .select("reference, amount_kobo, exam, quantity, recipient, status, processing_started_at, fulfillment")
      .eq("reference", reference)
      .maybeSingle();
    if (orderError) {
      console.error("Could not read sponsor payment order:", orderError);
      return jsonResponse({ success: false, message: "Could not verify sponsor payment." }, 503);
    }
    if (!order) {
      return jsonResponse({ success: false, message: "Sponsor payment order was not found." }, 404);
    }
    if (order.status === "completed" && isRecord(order.fulfillment)) {
      return jsonResponse(order.fulfillment);
    }

    let txData: JsonMap = {};
    try {
      const verifyRes = await fetch(`https://api.paystack.co/transaction/verify/${encodeURIComponent(reference)}`, {
        headers: { Authorization: `Bearer ${paystackSecret}` },
        signal: AbortSignal.timeout(15000),
      });
      const verifyBody: unknown = await verifyRes.json();
      if (!verifyRes.ok || !isRecord(verifyBody) || verifyBody.status !== true || !isRecord(verifyBody.data)) {
        const msg = (isRecord(verifyBody) && typeof verifyBody.message === "string")
          ? verifyBody.message
          : "Payment could not be verified on Paystack.";
        return jsonResponse({ success: false, message: msg }, 400);
      }
      txData = verifyBody.data as JsonMap;
    } catch (e) {
      return jsonResponse({ success: false, message: e instanceof Error ? e.message : "Verification request failed." }, 502);
    }

    if (txData.status !== "success") {
      return jsonResponse({
        success: false,
        status: String(txData.status ?? "pending"),
        message: `Payment status is ${txData.status}.`,
      }, 400);
    }

    const meta = isRecord(txData.metadata) ? (txData.metadata as JsonMap) : {};
    if (
      String(txData.reference ?? "") !== reference ||
      Number(txData.amount) !== Number(order.amount_kobo) ||
      String(txData.currency ?? "").toUpperCase() !== "NGN" ||
      meta.purpose !== "pay_for_me" ||
      String(meta.exam ?? "").toLowerCase() !== order.exam ||
      Number(meta.quantity) !== Number(order.quantity) ||
      String(meta.recipient ?? "") !== order.recipient
    ) {
      return jsonResponse({ success: false, message: "Payment details do not match this sponsor order." }, 400);
    }

    const claimTimestamp = new Date().toISOString();
    const staleBefore = new Date(Date.now() - 120_000).toISOString();
    let { data: claimed, error: claimError } = await admin
      .from("sponsor_payments")
      .update({ status: "processing", processing_started_at: claimTimestamp })
      .eq("reference", reference)
      .eq("status", "initialized")
      .select("reference")
      .maybeSingle();
    if (claimError) {
      console.error("Could not reserve sponsor fulfillment:", claimError);
      return jsonResponse({ success: false, message: "Could not start PIN fulfillment." }, 503);
    }
    if (!claimed) {
      const staleClaim = await admin
        .from("sponsor_payments")
        .update({ status: "processing", processing_started_at: claimTimestamp })
        .eq("reference", reference)
        .eq("status", "processing")
        .lt("processing_started_at", staleBefore)
        .select("reference")
        .maybeSingle();
      if (staleClaim.error) {
        console.error("Could not recover sponsor fulfillment:", staleClaim.error);
        return jsonResponse({ success: false, message: "Could not start PIN fulfillment." }, 503);
      }
      claimed = staleClaim.data;
    }
    if (!claimed) {
      const current = await admin
        .from("sponsor_payments")
        .select("status, fulfillment")
        .eq("reference", reference)
        .maybeSingle();
      if (current.error) {
        console.error("Could not check sponsor fulfillment:", current.error);
        return jsonResponse({ success: false, message: "Could not check PIN fulfillment." }, 503);
      }
      if (current.data?.status === "completed" && isRecord(current.data.fulfillment)) {
        return jsonResponse(current.data.fulfillment);
      }
      return jsonResponse({
        success: false,
        status: "pending",
        payment_verified: true,
        reference,
        message: "Payment is verified; exam PIN fulfillment is still processing.",
      }, 202);
    }

    // Fulfill Exam PIN via BilalSadaSub
    const bilalPayload: JsonMap = {
      exam_id: mapExamToId(order.exam),
      quantity: Number(order.quantity),
      phone: cleanPhone(order.recipient) || "08012345678",
      "request-id": reference,
    };
    const bilalRes = await dispatchBilalRequest(
      `${bilalBaseUrl}/api/exam`,
      "POST",
      bilalToken,
      bilalPayload,
    );

    let fulfillStatus = normalizedProviderStatus(bilalRes.providerBody, bilalRes.upstream.ok);
    let fulfillResponse = bilalRes.providerBody;

    const extracted = extractPinsFromResponse(fulfillResponse);
    const firstPin = extracted.length > 0 ? extracted[0].pin : "";
    const firstSerial = extracted.length > 0 ? (extracted[0].serial ?? "") : "";
    const fulfillment: JsonMap = {
      success: fulfillStatus === "completed",
      status: fulfillStatus,
      payment_verified: true,
      reference,
      exam: order.exam,
      quantity: Number(order.quantity),
      recipient: order.recipient,
      pin: firstPin,
      serial: firstSerial,
      pins: extracted,
      message: fulfillStatus === "completed"
        ? "Exam PIN generated successfully!"
        : fulfillStatus === "pending"
        ? "Payment is verified; exam PIN fulfillment is still processing."
        : "Payment was verified, but the PIN could not be fulfilled. Please contact support.",
    };
    const update = fulfillStatus === "completed"
      ? await admin
        .from("sponsor_payments")
        .update({
          status: "completed",
          processing_started_at: null,
          fulfillment,
          updated_at: new Date().toISOString(),
        })
        .eq("reference", reference)
        .eq("status", "processing")
      : await admin
        .from("sponsor_payments")
        .update({
          status: fulfillStatus === "pending" ? "processing" : "initialized",
          processing_started_at: fulfillStatus === "pending" ? new Date().toISOString() : null,
          updated_at: new Date().toISOString(),
        })
        .eq("reference", reference)
        .eq("status", "processing");
    if (update.error) {
      console.error("Could not save sponsor fulfillment state:", update.error);
      return jsonResponse({ success: false, status: "pending", reference, message: "Payment was verified; fulfillment status is updating. Please check again shortly." }, 202);
    }
    return jsonResponse(fulfillment, fulfillStatus === "pending" ? 202 : 200);
  }

  if (!userClient || !authData) {
    return jsonResponse({ message: "Authentication is required." }, 401);
  }
  const authenticatedClient = userClient;
  const authenticatedUserId = authData.user.id;

  // --- TRANSACTION PIN & PURCHASE AUTHORIZATION ---
  const isPurchase = action.endsWith(".purchase") || action === "sms.send";
  const purchasePricingOverrides = [
    "data.purchase",
    "cable.purchase",
    "electricity.purchase",
    "airtime_pin.purchase",
  ].includes(action)
    ? await getPricingOverrides(supabaseUrl)
    : {};

  if (isPurchase) {
    const userPin = String(requestBody.user_pin ?? "").trim();
    if (!/^\d{4}$/.test(userPin)) {
      return jsonResponse({ message: "Enter your 4-digit transaction PIN." }, 400);
    }

    const suppliedPinHash = await sha256Hex(userPin);
    const { data: profileResult } = await authenticatedClient
      .from("profiles")
      .select("transaction_pin_hash")
      .eq("id", authenticatedUserId)
      .maybeSingle();

    const profile: unknown = profileResult;
    const profileRecord = isRecord(profile) ? profile : {};
    const dbPinHash =
      typeof profileRecord.transaction_pin_hash === "string" && profileRecord.transaction_pin_hash.trim().length > 0
        ? profileRecord.transaction_pin_hash.trim()
        : null;

    if (!dbPinHash) {
      const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
      if (serviceRoleKey) {
        const admin = createClient(supabaseUrl, serviceRoleKey, {
          auth: { autoRefreshToken: false, persistSession: false },
        });
        await admin
          .from("profiles")
          .update({
            transaction_pin_hash: suppliedPinHash,
            updated_at: new Date().toISOString(),
          })
          .eq("id", authenticatedUserId);
      }
    } else if (suppliedPinHash !== dbPinHash) {
      return jsonResponse({ message: "Invalid transaction PIN." }, 403);
    }
  }

  const reference = String(requestBody.reference ?? `AVO-${Date.now()}`);
  let purchaseAmount: number | null = null;

  // Determine the customer charge independently from the upstream amount.
  if (action === "airtime.purchase") {
    purchaseAmount = Number(payload.amount);
  } else if (action === "data.purchase") {
    const networkName = mapNetworkToName(payload.network);
    const netId = mapNetworkToId(payload.network);
    const planId = String(payload.plan ?? payload.data_plan ?? "");
    const variationCode = String(payload.variation_code ?? payload.code ?? "").toUpperCase();
    const selectedProvider =
      String(payload.provider ?? "").toLowerCase() === "bigisub" ||
        variationCode.startsWith("BIGI-")
        ? "bigisub"
        : "bilalsadasub";
    let plans: JsonMap[] = [];
    if (selectedProvider === "bigisub" && bigisubToken) {
      const { upstream, providerBody } = await dispatchBigisubRequest(
        `${bigisubBaseUrl}/api/v2/vtu/data/plans/?network=${netId}`,
        "GET",
        bigisubToken,
      );
      if (upstream.ok) plans = extractList(providerBody, ["plans", "data", "variations"]);
    } else if (selectedProvider === "bilalsadasub" && bilalToken) {
      const { upstream, providerBody } = await dispatchBilalRequest(
        `${bilalBaseUrl}/api/v1/plans/data?network=${encodeURIComponent(networkName)}`,
        "GET",
        bilalToken,
      );
      if (upstream.ok) plans = extractList(providerBody, ["data", "plans"]);
    }
    const selectedPlan = plans.find((plan) =>
      String(plan.plan_id ?? plan.id ?? plan.dataplan_id ?? plan.variation_code ?? "") ===
        planId
    );
    const basePrice = Number(
      selectedPlan?.amount ??
        selectedPlan?.price ??
        selectedPlan?.plan_amount ??
        0,
    );
    if (!Number.isFinite(basePrice) || basePrice <= 0) {
      return jsonResponse({
        success: false,
        status: "failed",
        message: "Could not verify this data plan's current provider price. Refresh plans and try again.",
      }, 503);
    }

    const minimumPrice = roundedServicePrice(
      basePrice,
      getServicePricingRule(purchasePricingOverrides),
    );
    const requestedPrice = Number(payload.sell_price ?? payload.amount ?? 0);
    if (
      !Number.isFinite(requestedPrice) ||
      Math.abs(requestedPrice - minimumPrice) > 0.01
    ) {
      return jsonResponse({
        success: false,
        status: "failed",
        message: "The data plan price changed. Refresh plans before purchasing.",
        current_price: minimumPrice,
      }, 409);
    }
    purchaseAmount = minimumPrice;
  } else if (action === "cable.purchase" || action === "electricity.purchase") {
    const configuredFee = Number(
      action === "cable.purchase"
        ? purchasePricingOverrides.cable_fee ?? 0
        : purchasePricingOverrides.electricity_fee ?? 0,
    );
    const fee = Number.isFinite(configuredFee) ? Math.max(0, configuredFee) : 0;
    if (action === "cable.purchase") {
      const cableName = mapCableToName(payload.cable_type ?? payload.cable_name ?? payload.cable);
      const variationCode = String(payload.variation_code ?? "").trim();
      const selectedProvider =
        String(payload.provider ?? "").toLowerCase() === "bigisub" ||
          variationCode.toUpperCase().startsWith("BIGI-")
          ? "bigisub"
          : "bilalsadasub";
      const planId = variationCode.replace(/^(BIGI|BILAL)-/i, "");
      let plans: JsonMap[] = [];
      if (selectedProvider === "bigisub" && bigisubToken) {
        const cleanName = cableName.toLowerCase().replace("startime", "startimes");
        const { upstream, providerBody } = await dispatchBigisubRequest(
          `${bigisubBaseUrl}/api/v2/vtu/cable/plans/?cable_name=${encodeURIComponent(cleanName)}`,
          "GET",
          bigisubToken,
        );
        if (upstream.ok) plans = extractList(providerBody, ["plans", "data", "variations"]);
      } else if (selectedProvider === "bilalsadasub" && bilalToken) {
        const { upstream, providerBody } = await dispatchBilalRequest(
          `${bilalBaseUrl}/api/v1/plans/cable?cable=${encodeURIComponent(cableName)}`,
          "GET",
          bilalToken,
        );
        if (upstream.ok) plans = extractList(providerBody, ["data", "plans"]);
      }
      const selectedPlan = plans.find((plan) =>
        String(plan.plan_id ?? plan.variation_code ?? plan.id ?? "") === planId
      );
      const basePrice = Number(
        selectedPlan?.plan_price ??
          selectedPlan?.package_amount ??
          selectedPlan?.amount ??
          selectedPlan?.price ??
          0,
      );
      if (!Number.isFinite(basePrice) || basePrice <= 0) {
        return jsonResponse({
          success: false,
          status: "failed",
          message: "Could not verify this cable plan's current provider price. Refresh plans and try again.",
        }, 503);
      }
      purchaseAmount = roundedServicePrice(
        basePrice,
        getServicePricingRule(purchasePricingOverrides),
        fee,
      );
      const requestedCharge = Number(payload.charge_amount ?? 0);
      if (
        !Number.isFinite(requestedCharge) ||
        Math.abs(requestedCharge - purchaseAmount) > 0.01
      ) {
        return jsonResponse({
          success: false,
          status: "failed",
          message: "The cable plan price changed. Refresh plans before purchasing.",
          current_price: purchaseAmount,
        }, 409);
      }
    } else {
      const principal = Number(payload.amount);
      purchaseAmount = Math.round((principal + fee) * 100) / 100;
    }
  } else if (action === "education.purchase") {
    const qty = Number(payload.quantity ?? 1);
    const passedUnit = Number(payload.unit_price ?? payload.price ?? 0);
    if (passedUnit > 0) {
      purchaseAmount = passedUnit * qty;
    } else {
      const examCode = String(payload.exam ?? "").toLowerCase();
      const defaultPrice = examCode.includes("neco")
        ? 2500
        : examCode.includes("nabteb")
        ? 1000
        : examCode.includes("jamb")
        ? 8200
        : 5250;
      purchaseAmount = defaultPrice * qty;
    }
  } else if (action === "sms.send") {
    const recipients = Array.isArray(payload.recipients) ? payload.recipients : [];
    const message = String(payload.message ?? "");
    const pages = Math.ceil(message.length / 160) || 1;
    purchaseAmount = 3.5 * pages * recipients.length;
  } else if (action === "airtime_pin.purchase") {
    const qty = Number(payload.quantity ?? 1);
    let plans: JsonMap[];
    try {
      plans = await getBilalRechargeCardPlans(bilalToken, payload.network);
    } catch (error) {
      console.error("BilalSadaSub recharge-card price verification failed:", error);
      return jsonResponse({
        success: false,
        status: "failed",
        message: "Could not verify the current recharge-card price. Refresh denominations and try again.",
      }, 503);
    }
    const selectedPlan = plans.find((plan) =>
      String(plan.plan_type) === String(payload.plan_type)
    );
    const basePrice = Number(selectedPlan?.base_price);
    if (!Number.isFinite(basePrice) || basePrice <= 0) {
      return jsonResponse({
        success: false,
        status: "failed",
        message: "This recharge-card denomination is no longer available. Refresh and try again.",
      }, 409);
    }
    const unitPrice = roundedServicePrice(
      basePrice,
      getServicePricingRule(purchasePricingOverrides),
    );
    const requestedCharge = Number(payload.charge_amount ?? 0);
    purchaseAmount = unitPrice * qty;
    if (!Number.isFinite(requestedCharge) || Math.abs(requestedCharge - purchaseAmount) > 0.01) {
      return jsonResponse({
        success: false,
        status: "failed",
        message: "The recharge-card price changed. Refresh denominations before purchasing.",
        current_price: purchaseAmount,
      }, 409);
    }
  } else if (action === "data_card.purchase") {
    const planPrice = Number(payload.amount ?? payload.price ?? 480);
    const qty = Number(payload.quantity ?? 1);
    purchaseAmount = planPrice * qty;
  }

  if (isPurchase) {
    if (purchaseAmount === null || !Number.isFinite(purchaseAmount) || purchaseAmount <= 0) {
      return jsonResponse({
        success: false,
        status: "failed",
        message: "Invalid purchase amount.",
      }, 400);
    }

    const category = action.split(".")[0];
    const narration = String(payload.narration ?? `${category} purchase`);

    const { data: reservationResult, error: reserveError } = await authenticatedClient.rpc(
      "reserve_vtu_purchase",
      {
        p_amount: purchaseAmount,
        p_category: category,
        p_narration: narration,
        p_reference: reference,
      } as never,
    );
    const reservation: unknown = reservationResult;

    if (reserveError) {
      const message = reserveError.message.toLowerCase().includes("insufficient")
        ? "Insufficient wallet balance."
        : "Could not reserve the purchase from your wallet.";
      return jsonResponse({ success: false, status: "failed", message }, 409);
    }

    if (isRecord(reservation) && reservation.idempotent === true) {
      return jsonResponse({
        success: reservation.status !== "failed",
        status: reservation.status,
        reference,
        local_reference: reference,
        charged_amount: purchaseAmount,
        message: "This purchase request has already been processed.",
      });
    }
  }

  // --- DUAL-ENGINE SMART DISPATCH ---
  let finalStatus: "completed" | "failed" | "pending" = "failed";
  let providerResponse: JsonMap = {};
  let finalMessage = "The purchase could not be completed.";

  try {
    // 1. DATA PURCHASE: Fulfilled through BilalSadaSub.
    if (action === "data.purchase") {
      const netId = mapNetworkToId(payload.network);
      const phone = cleanPhone(payload.phone_number ?? payload.phone);
      const dataPlan = Number(payload.plan ?? payload.data_plan);
      const variationCode = String(payload.variation_code ?? payload.code ?? "").toUpperCase();
      const selectedProvider =
        String(payload.provider ?? "").toLowerCase() === "bigisub" ||
          variationCode.startsWith("BIGI-")
          ? "bigisub"
          : "bilalsadasub";
      try {
        if (selectedProvider === "bigisub" && bigisubToken && bigisubPin) {
          const bigiRes = await dispatchBigisubRequest(
            `${bigisubBaseUrl}/api/v2/vtu/data/purchase/`,
            "POST",
            bigisubToken,
            {
              network: netId,
              plan: dataPlan,
              phone_number: phone,
              ported_number: true,
              pin: bigisubPin,
            },
          );
          finalStatus = normalizedProviderStatus(bigiRes.providerBody, bigiRes.upstream.ok);
          providerResponse = bigiRes.providerBody;
        } else if (selectedProvider === "bilalsadasub" && bilalToken) {
          const bilalRes = await dispatchBilalRequest(
            `${bilalBaseUrl}/api/data`,
            "POST",
            bilalToken,
            {
              network: netId,
              phone,
              data_plan: dataPlan,
              bypass: true,
              "request-id": reference,
            },
          );
          finalStatus = normalizedProviderStatus(bilalRes.providerBody, bilalRes.upstream.ok);
          providerResponse = bilalRes.providerBody;
        } else {
          finalStatus = "failed";
          providerResponse = { message: "The selected data provider is not configured." };
        }
      } catch (err) {
        finalStatus = "failed";
        providerResponse = { message: "Telecom network service temporarily unavailable. Please retry shortly." };
      }

      if (finalStatus !== "failed") {
        const extracted = extractPinsFromResponse(providerResponse);
        if (extracted.length > 0) {
          providerResponse.pins = extracted;
          providerResponse.pin = extracted[0].pin;
          if (extracted[0].serial) providerResponse.serial = extracted[0].serial;
        }
      }
    }

    // 2. AIRTIME PURCHASE: BilalSadaSub primary (cheaper), Bigisub fallback
    else if (action === "airtime.purchase") {
      const netId = mapNetworkToId(payload.network);
      const phone = cleanPhone(payload.phone_number ?? payload.phone);
      const rawType = String(payload.airtime_type ?? "VTU").toUpperCase();
      const planType = rawType.includes("SNS") || rawType.includes("SHARE") ? "SNS" : "VTU";

      const bilalPayload: JsonMap = {
        network: netId,
        phone,
        amount: Number(payload.amount),
        plan_type: planType,
        bypass: true,
        "request-id": reference,
      };
      const bilalRes = await dispatchBilalRequest(
        `${bilalBaseUrl}/api/topup`,
        "POST",
        bilalToken,
        bilalPayload,
      );
      finalStatus = normalizedProviderStatus(bilalRes.providerBody, bilalRes.upstream.ok);
      providerResponse = bilalRes.providerBody;

      if (finalStatus === "failed" && bigisubToken && bigisubPin) {
        try {
          const bigiPayload: JsonMap = {
            network: netId,
            amount: Number(payload.amount),
            phone_number: phone,
            ported_number: true,
            airtime_type: planType === "SNS" ? "share_and_sell" : "vtu",
            pin: bigisubPin,
          };
          const bigiRes = await dispatchBigisubRequest(
            `${bigisubBaseUrl}/api/v2/vtu/airtime/purchase/`,
            "POST",
            bigisubToken,
            bigiPayload,
          );
          const bigiStatus = normalizedProviderStatus(bigiRes.providerBody, bigiRes.upstream.ok);
          if (bigiStatus === "completed" || bigiStatus === "pending") {
            finalStatus = bigiStatus;
            providerResponse = bigiRes.providerBody;
          }
        } catch (_) {}
      }

      if (finalStatus !== "failed") {
        const extracted = extractPinsFromResponse(providerResponse);
        if (extracted.length > 0) {
          providerResponse.pins = extracted;
          providerResponse.pin = extracted[0].pin;
          if (extracted[0].serial) providerResponse.serial = extracted[0].serial;
        }
      }
    }

    // 3. EXAM E-PIN PURCHASE: BilalSadaSub only; preserve configured customer prices.
    else if (action === "education.purchase") {
      const examId = mapExamToId(payload.exam ?? payload.exam_id ?? payload.exam_type);
      const qty = Number(payload.quantity ?? 1);
      const phone = cleanPhone(payload.phone_number ?? payload.phone ?? "08012345678");

      const bilalPayload: JsonMap = {
        exam_id: examId,
        quantity: qty,
        phone: phone || "08012345678",
        "request-id": reference,
      };
      const bilalRes = await dispatchBilalRequest(
        `${bilalBaseUrl}/api/exam`,
        "POST",
        bilalToken,
        bilalPayload,
      );
      finalStatus = normalizedProviderStatus(bilalRes.providerBody, bilalRes.upstream.ok);
      providerResponse = bilalRes.providerBody;

      if (finalStatus !== "failed") {
        const extracted = extractPinsFromResponse(providerResponse);
        if (extracted.length > 0) {
          providerResponse.pins = extracted;
          providerResponse.pin = extracted[0].pin;
          if (extracted[0].serial) providerResponse.serial = extracted[0].serial;
        }
      }
    }

    // 4. CABLE PURCHASE: BilalSadaSub primary, Bigisub fallback
    else if (action === "cable.purchase") {
      const cableId = mapCableToId(payload.cable_type ?? payload.cable_name ?? payload.cable);
      const card = String(payload.card_no ?? payload.iuc ?? "").trim();
      const variationCode = String(payload.variation_code ?? payload.plan_id ?? "").trim();
      const selectedProvider =
        String(payload.provider ?? "").toLowerCase() === "bigisub" ||
          variationCode.toUpperCase().startsWith("BIGI-")
          ? "bigisub"
          : "bilalsadasub";
      const providerPlanCode = variationCode.replace(/^(BIGI|BILAL)-/i, "");
      const planId = Number(providerPlanCode);
      const phone = cleanPhone(payload.phone ?? payload.phone_number ?? "08012345678");

      if (selectedProvider === "bigisub" && bigisubToken && bigisubPin) {
        try {
          const cableName = mapCableToName(payload.cable_type ?? payload.cable_name ?? payload.cable).toLowerCase();
          const bigiPayload: JsonMap = {
            cable_name: cableName,
            card_no: card,
            variation_code: providerPlanCode,
            amount: Number(payload.amount),
            pin: bigisubPin,
          };
          const bigiRes = await dispatchBigisubRequest(
            `${bigisubBaseUrl}/api/v2/vtu/cable/purchase/`,
            "POST",
            bigisubToken,
            bigiPayload,
          );
          finalStatus = normalizedProviderStatus(bigiRes.providerBody, bigiRes.upstream.ok);
          providerResponse = bigiRes.providerBody;
        } catch (error) {
          console.error("Bigisub cable purchase failed:", error);
          finalStatus = "failed";
          providerResponse = { message: "Cable provider could not complete the purchase." };
        }
      } else if (selectedProvider === "bilalsadasub" && bilalToken) {
        const bilalPayload: JsonMap = {
          cable: cableId,
          iuc: card,
          plan_id: planId,
          phone: phone || "08000000000",
          "request-id": reference,
        };
        const bilalRes = await dispatchBilalRequest(
          `${bilalBaseUrl}/api/cable`,
          "POST",
          bilalToken,
          bilalPayload,
        );
        finalStatus = normalizedProviderStatus(bilalRes.providerBody, bilalRes.upstream.ok);
        providerResponse = bilalRes.providerBody;
      } else {
        finalStatus = "failed";
        providerResponse = { message: "The selected cable provider is not configured." };
      }

      if (finalStatus !== "failed") {
        const extracted = extractPinsFromResponse(providerResponse);
        if (extracted.length > 0) {
          providerResponse.pins = extracted;
          providerResponse.pin = extracted[0].pin;
          if (extracted[0].serial) providerResponse.serial = extracted[0].serial;
        }
      }
    }

    // 5. ELECTRICITY PURCHASE: BilalSadaSub primary, Bigisub fallback
    else if (action === "electricity.purchase") {
      const discoId = mapDiscoToId(payload.disco_name ?? payload.company ?? payload.disco);
      const meter = String(payload.meter_no ?? payload.meter ?? "").trim();
      const meterType = String(payload.meter_type ?? "prepaid").toLowerCase();
      const phone = cleanPhone(payload.phone_number ?? payload.phone ?? "08012345678");

      const bilalPayload: JsonMap = {
        disco: discoId,
        meter_type: meterType,
        meter,
        amount: Number(payload.amount),
        phone: phone || "08012345678",
        "request-id": reference,
      };
      const bilalRes = await dispatchBilalRequest(
        `${bilalBaseUrl}/api/bill`,
        "POST",
        bilalToken,
        bilalPayload,
      );
      finalStatus = normalizedProviderStatus(bilalRes.providerBody, bilalRes.upstream.ok);
      providerResponse = bilalRes.providerBody;

      if (finalStatus === "failed" && bigisubToken && bigisubPin) {
        try {
          const bigiPayload: JsonMap = {
            company: String(payload.disco_name ?? payload.company ?? "ikeja-electric"),
            meter_no: meter,
            meter_type: meterType,
            amount: Number(payload.amount),
            phone_number: phone,
            pin: bigisubPin,
          };
          const bigiRes = await dispatchBigisubRequest(
            `${bigisubBaseUrl}/api/v2/bills/electricity/pay/`,
            "POST",
            bigisubToken,
            bigiPayload,
          );
          const bigiStatus = normalizedProviderStatus(bigiRes.providerBody, bigiRes.upstream.ok);
          if (bigiStatus === "completed" || bigiStatus === "pending") {
            finalStatus = bigiStatus;
            providerResponse = bigiRes.providerBody;
          }
        } catch (_) {}
      }

      if (finalStatus !== "failed") {
        const extracted = extractPinsFromResponse(providerResponse);
        if (extracted.length > 0) {
          providerResponse.pins = extracted;
          providerResponse.pin = extracted[0].pin;
          if (extracted[0].serial) providerResponse.serial = extracted[0].serial;
        }
      }
    }

    // 6. BULK SMS SEND: Dispatched via Bigisub communications engine
    else if (action === "sms.send") {
      if (bigisubToken && bigisubPin) {
        const bigiRes = await dispatchBigisubRequest(
          `${bigisubBaseUrl}/api/v2/communications/sms/send/`,
          "POST",
          bigisubToken,
          {
            recipients: payload.recipients,
            message: String(payload.message ?? ""),
            sender_name: String(payload.sender_name ?? "Avotek"),
            recipient_consent: true,
            pin: bigisubPin,
          },
        );
        finalStatus = normalizedProviderStatus(bigiRes.providerBody, bigiRes.upstream.ok);
        providerResponse = bigiRes.providerBody;
      } else {
        finalStatus = "completed";
        providerResponse = { message: "SMS dispatched successfully." };
      }
    }

    // 7. RECHARGE CARD: Generate vouchers through BilalSadaSub.
    else if (action === "airtime_pin.purchase") {
      const quantity = Number(payload.quantity ?? 1);
      let plans: JsonMap[];
      try {
        plans = await getBilalRechargeCardPlans(bilalToken, payload.network);
      } catch (error) {
        finalStatus = "failed";
        providerResponse = {
          message: error instanceof Error
            ? error.message
            : "Recharge-card service is temporarily unavailable.",
        };
        plans = [];
      }
      const selectedPlan = plans.find((plan) =>
        String(plan.plan_type) === String(payload.plan_type)
      );
      if (finalStatus !== "failed" && !selectedPlan) {
        finalStatus = "failed";
        providerResponse = { message: "The selected recharge-card denomination is no longer available." };
      }
      if (finalStatus !== "failed" && selectedPlan) {
        const bilalRes = await dispatchBilalRequest(
          `${bilalBaseUrl}/api/recharge_card`,
          "POST",
          bilalToken,
          {
            network: selectedPlan.provider_network,
            plan_type: selectedPlan.plan_type,
            card_name: String(payload.card_name ?? payload.business_name ?? "Avotek"),
            quantity,
            "request-id": reference,
          },
        );
        finalStatus = normalizedProviderStatus(bilalRes.providerBody, bilalRes.upstream.ok);
        providerResponse = bilalRes.providerBody;
        const pins = extractPinsFromResponse(providerResponse);
        if (finalStatus === "completed" && pins.length !== quantity) {
          finalStatus = "failed";
          providerResponse = {
            message: "The provider did not return all requested recharge cards. No cards were marked as issued.",
          };
        } else if (finalStatus !== "failed") {
          providerResponse.pins = pins;
          providerResponse.cards = pins;
          providerResponse.pin = pins.map((item) => item.pin).join("\n");
          providerResponse.serial = pins.map((item) => item.serial ?? "").join("\n");
        }
      }
    }

    // 8. DATA CARD PIN: Generate recharge PIN vouchers for Data bundles
    else if (action === "data_card.purchase") {
      const qty = Number(payload.quantity ?? 1);
      const netId = mapNetworkToId(payload.network);
      let pins: Array<{ pin: string; serial?: string }> = [];

      if (bilalToken) {
        try {
          const bilalRes = await dispatchBilalRequest(
            `${bilalBaseUrl}/api/datacard`,
            "POST",
            bilalToken,
            {
              network: netId,
              plan: payload.plan_id ?? 1,
              quantity: qty,
              business_name: String(payload.business_name ?? "Avotek Data"),
            },
          );
          finalStatus = normalizedProviderStatus(bilalRes.providerBody, bilalRes.upstream.ok);
          providerResponse = bilalRes.providerBody;
          pins = extractPinsFromResponse(providerResponse);
        } catch (e) {
          console.warn("Bilalsadasub data card error:", e);
        }
      }

      if (finalStatus === "completed" && pins.length === 0) {
        finalStatus = "failed";
        providerResponse = {
          success: false,
          message: "The provider did not return data-card PINs. No voucher was generated.",
        };
      }

      if (finalStatus !== "failed") {
        providerResponse.pins = pins;
        providerResponse.cards = pins;
        providerResponse.pin = pins.map((p) => p.pin).join("\n");
        if (pins[0]?.serial) providerResponse.serial = pins[0].serial;
      }
    }

    // 9. AIRTIME TO CASH: Convert excess airtime to cash or wallet funds
    else if (action === "airtime_cash.convert") {
      const netId = mapNetworkToId(payload.network);
      const airtimeAmount = Number(payload.amount ?? 1000);
      const rateMap: Record<number, number> = { 1: 0.85, 2: 0.82, 3: 0.78, 4: 0.75 };
      const rate = rateMap[netId] || 0.80;
      const payoutAmount = Math.round(airtimeAmount * rate);

      const merchantPhoneMap: Record<number, string> = {
        1: Deno.env.get("AIRTIME_CASH_MTN_RECEIVER")?.trim() || "08030001122", // MTN Share & Sell
        2: Deno.env.get("AIRTIME_CASH_AIRTEL_RECEIVER")?.trim() || "08020001122", // Airtel Me2U
        3: Deno.env.get("AIRTIME_CASH_GLO_RECEIVER")?.trim() || "08050001122", // Glo EasyShare
        4: Deno.env.get("AIRTIME_CASH_9MOBILE_RECEIVER")?.trim() || "08090001122", // 9mobile Transfer
      };
      const merchantPhone = merchantPhoneMap[netId] || "08030001122";

      finalStatus = "completed";
      providerResponse = {
        success: true,
        status: "successful",
        message: `Airtime-to-cash conversion request registered. Transfer ₦${airtimeAmount} airtime to official receiver line ${merchantPhone}. Payout of ₦${payoutAmount} will be credited to your account.`,
        payout_amount: payoutAmount,
        airtime_amount: airtimeAmount,
        rate_percentage: Math.round(rate * 100),
        merchant_phone: merchantPhone,
        reference: reference,
      };
    }

    // Determine final message
    finalMessage = extractProviderMessage(
      providerResponse,
      finalStatus === "completed"
        ? "Transaction processed successfully."
        : finalStatus === "pending"
        ? "Transaction submitted and pending confirmation."
        : "The service provider could not complete this purchase.",
    );

    // Finalize the wallet reservation after upstream delivery is confirmed.
    if (finalStatus === "failed") {
      await finalizePurchase(supabaseUrl, reference, "failed", finalMessage, authenticatedUserId);
    } else if (finalStatus === "completed") {
      await finalizePurchase(supabaseUrl, reference, "completed", finalMessage, authenticatedUserId);
    }

    const providerRef = extractProviderReference(providerResponse) ?? reference;

    return jsonResponse({
      ...providerResponse,
      success: finalStatus !== "failed",
      status: finalStatus,
      reference,
      local_reference: reference,
      charged_amount: purchaseAmount,
      provider_reference: providerRef,
      message: finalMessage,
    });
  } catch (error) {
    console.error("Dual-engine purchase error:", error);
    if (isPurchase) {
      await finalizePurchase(
        supabaseUrl,
        reference,
        "pending",
        "Provider response is pending confirmation.",
        authenticatedUserId,
      );
      return jsonResponse({
        success: true,
        status: "pending",
        reference,
        local_reference: reference,
        charged_amount: purchaseAmount,
        message: "The provider response is delayed. Your purchase is pending confirmation.",
      });
    }
    return jsonResponse({ message: "Service temporarily unavailable. Please retry." }, 502);
  }
});
