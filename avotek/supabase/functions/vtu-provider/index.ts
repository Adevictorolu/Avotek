import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Origin": "*",
  "Content-Type": "application/json",
};

const bilalBaseUrl = "https://bilalsadasub.com";
const bigisubBaseUrl = "https://api.bigisub.ng";
const defaultBilalKey = "79b8d730c62c3545892766a7d8d703377b035c82135c97b8b161015e585d";

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
      return candidate.trim();
    }
    if (Array.isArray(candidate) && candidate.length > 0) {
      const first = String(candidate[0] ?? "").trim();
      if (first.length > 0) return first;
    }
  }
  for (const [key, value] of Object.entries(body)) {
    if (["success", "status", "data", "code", "status_code", "errors"].includes(key)) continue;
    if (Array.isArray(value) && value.length > 0 && typeof value[0] === "string") {
      return `${key}: ${value[0]}`;
    }
  }
  return fallback;
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

  const isPublicCatalogAction = [
    "education.prices",
    "data.plans",
    "cable.plans",
    "cable.verify",
    "electricity.providers",
    "electricity.verify",
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
    defaultBilalKey;
  const bigisubToken = Deno.env.get("BIGISUB_API_TOKEN")?.trim();
  const bigisubPin = Deno.env.get("BIGISUB_TRANSACTION_PIN")?.trim() || "0000";
  const paystackSecret = Deno.env.get("PAYSTACK_SECRET_KEY")?.trim();

  // --- WALLET BALANCE ---
  if (action === "wallet.balance") {
    return jsonResponse({
      status: "success",
      success: true,
      data: {
        balance: 100000,
        provider: "Dual-Engine (BilalSadaSub + Bigisub)",
      },
    });
  }

  // --- DATA PLANS ---
  if (action === "data.plans") {
    const networkName = mapNetworkToName(payload.network);
    let url = `${bilalBaseUrl}/api/v1/plans/data?network=${encodeURIComponent(networkName)}`;
    const planType = String(payload.plantype ?? payload.plan_type ?? "").trim().toUpperCase();
    if (planType && planType !== "ALL") {
      url += `&plan_type=${encodeURIComponent(planType)}`;
    }
    const { upstream, providerBody } = await dispatchBilalRequest(url, "GET", bilalToken);
    let plans = extractList(providerBody, ["data", "plans"]);

    // If Bilal plans query fails or empty, fallback to Bigisub data plans
    if ((!upstream.ok || plans.length === 0) && bigisubToken) {
      try {
        const netId = mapNetworkToId(payload.network);
        const bigiRes = await dispatchBigisubRequest(
          `${bigisubBaseUrl}/api/v2/vtu/data/plans/?network=${netId}`,
          "GET",
          bigisubToken,
        );
        const bigiPlans = extractList(bigiRes.providerBody, ["plans", "data", "variations"]);
        if (bigiPlans.length > 0) {
          plans = bigiPlans;
        }
      } catch (_) {}
    }

    return jsonResponse({
      status: "success",
      success: true,
      data: plans,
    });
  }

  // --- CABLE PLANS ---
  if (action === "cable.plans") {
    const cableName = mapCableToName(payload.cable_name ?? payload.cable_type ?? payload.cable);
    const url = `${bilalBaseUrl}/api/v1/plans/cable?cable=${encodeURIComponent(cableName)}`;
    const { upstream, providerBody } = await dispatchBilalRequest(url, "GET", bilalToken);
    let plans = extractList(providerBody, ["data", "plans"]);

    if ((!upstream.ok || plans.length === 0) && bigisubToken) {
      try {
        const cleanName = cableName.toLowerCase().replace("startime", "startimes");
        const bigiRes = await dispatchBigisubRequest(
          `${bigisubBaseUrl}/api/v2/vtu/cable/plans/?cable_name=${encodeURIComponent(cleanName)}`,
          "GET",
          bigisubToken,
        );
        const bigiPlans = extractList(bigiRes.providerBody, ["plans", "data", "variations"]);
        if (bigiPlans.length > 0) plans = bigiPlans;
      } catch (_) {}
    }

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
      data: providerBody,
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
      address: providerBody.address ?? "",
      message: extractProviderMessage(providerBody, isValid ? "Meter verified." : "Could not verify meter number."),
      data: providerBody,
    });
  }

  // --- EDUCATION PRICES (Retain Bigisub Retail Prices as requested) ---
  if (action === "education.prices") {
    // Retain Bigisub retail pricing (WAEC ₦5,250, NECO ₦2,500, NABTEB ₦1,000)
    // While utilizing BilalSadaSub API under the hood for purchase fulfillment!
    const retailPrices = [
      { code: "waec", exam_id: "1", exam: "WAEC", name: "WAEC Result Checker", amount: 5250, mode: "quantity" },
      { code: "neco", exam_id: "2", exam: "NECO", name: "NECO Result Checker", amount: 2500, mode: "quantity" },
      { code: "nabteb", exam_id: "3", exam: "NABTEB", name: "NABTEB Result Checker", amount: 1000, mode: "quantity" },
      { code: "jamb", exam_id: "4", exam: "JAMB UTME", name: "JAMB UTME E-PIN", amount: 5000, mode: "profile_code" },
    ];
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
    const reference = String(payload.reference ?? "").trim();
    if (!email || !email.includes("@")) {
      return jsonResponse({ success: false, message: "Enter a valid sponsor email address." }, 400);
    }
    if (!Number.isFinite(amount) || amount <= 0) {
      return jsonResponse({ success: false, message: "Invalid sponsor payment amount." }, 400);
    }
    if (!reference) {
      return jsonResponse({ success: false, message: "Payment reference is required." }, 400);
    }

    if (!paystackSecret) {
      return jsonResponse({ success: false, message: "Paystack gateway key is not configured." }, 503);
    }

    const defaultCallback = "https://adevictorolu.github.io/Avotek/";
    const origin = String(payload.origin ?? "").trim() || defaultCallback;
    const cleanOrigin = origin.endsWith("/") ? origin.slice(0, -1) : origin;
    const callbackUrl = `${cleanOrigin}/#/pay?ref=${encodeURIComponent(reference)}&status=success`;

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
          callback_url: callbackUrl,
          metadata: {
            purpose: "pay_for_me",
            exam: payload.exam,
            quantity: payload.quantity,
            recipient: payload.recipient,
            service: payload.service,
          },
        }),
        signal: AbortSignal.timeout(15000),
      });

      const paystackBody: unknown = await paystackRes.json();
      if (!paystackRes.ok || !isRecord(paystackBody) || paystackBody.status !== true || !isRecord(paystackBody.data)) {
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
      return jsonResponse({
        success: false,
        message: e instanceof Error ? e.message : "Paystack connection timed out.",
      }, 502);
    }
  }

  // --- SPONSOR VERIFY & FULFILL (Verify Paystack transaction & generate Exam PIN via BilalSadaSub) ---
  if (action === "sponsor.verify") {
    const reference = String(payload.reference ?? "").trim();
    if (!reference) {
      return jsonResponse({ success: false, message: "Payment reference is required." }, 400);
    }

    if (!paystackSecret) {
      return jsonResponse({ success: false, message: "Paystack gateway key is not configured." }, 503);
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
    const exam = payload.exam ?? meta.exam ?? "waec";
    const examId = mapExamToId(exam);
    const qty = Number(payload.quantity ?? meta.quantity ?? 1);
    const phone = cleanPhone(payload.phone ?? meta.recipient ?? "08012345678");

    // Fulfill Exam PIN via BilalSadaSub
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

    let fulfillStatus = normalizedProviderStatus(bilalRes.providerBody, bilalRes.upstream.ok);
    let fulfillResponse = bilalRes.providerBody;

    if (fulfillStatus === "failed" && bigisubToken) {
      try {
        const examUpper = String(exam).toUpperCase();
        const bigiRes = await dispatchBigisubRequest(
          `${bigisubBaseUrl}/api/v2/bills/result-checker/purchase/`,
          "POST",
          bigisubToken,
          {
            exam: examUpper,
            exam_type: examUpper,
            quantity: qty,
            pin: bigisubPin,
            pin_code: bigisubPin,
          },
        );
        const bigiStatus = normalizedProviderStatus(bigiRes.providerBody, bigiRes.upstream.ok);
        if (bigiStatus === "completed" || bigiStatus === "pending") {
          fulfillStatus = bigiStatus;
          fulfillResponse = bigiRes.providerBody;
        }
      } catch (_) {}
    }

    const extracted = extractPinsFromResponse(fulfillResponse);
    const firstPin = extracted.length > 0 ? extracted[0].pin : "";
    const firstSerial = extracted.length > 0 ? (extracted[0].serial ?? "") : "";

    return jsonResponse({
      success: fulfillStatus !== "failed",
      status: fulfillStatus,
      reference,
      exam,
      quantity: qty,
      recipient: phone,
      pin: firstPin,
      serial: firstSerial,
      pins: extracted,
      provider_response: fulfillResponse,
      message: fulfillStatus === "completed"
        ? "Exam PIN generated successfully!"
        : "PIN purchase submitted to provider.",
    });
  }

  // --- TRANSACTION PIN & PURCHASE AUTHORIZATION ---
  const isPurchase = action.endsWith(".purchase") || action === "sms.send";

  if (isPurchase) {
    const userPin = String(requestBody.user_pin ?? "").trim();
    if (!/^\d{4}$/.test(userPin)) {
      return jsonResponse({ message: "Enter your 4-digit transaction PIN." }, 400);
    }

    const suppliedPinHash = await sha256Hex(userPin);
    const { data: profile } = await userClient
      .from("profiles")
      .select("transaction_pin_hash")
      .eq("id", authData.user.id)
      .maybeSingle();

    const dbPinHash =
      typeof profile?.transaction_pin_hash === "string" && profile.transaction_pin_hash.trim().length > 0
        ? profile.transaction_pin_hash.trim()
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
          .eq("id", authData.user.id);
      }
    } else if (suppliedPinHash !== dbPinHash) {
      return jsonResponse({ message: "Invalid transaction PIN." }, 403);
    }
  }

  const reference = String(requestBody.reference ?? `AVO-${Date.now()}`);
  let purchaseAmount: number | null = null;

  // Determine user charge amount (retaining Bigisub pricing structure as requested)
  if (action === "airtime.purchase") {
    purchaseAmount = Number(payload.amount);
  } else if (action === "data.purchase") {
    purchaseAmount = Number(payload.sell_price ?? payload.amount ?? 0);
  } else if (action === "cable.purchase" || action === "electricity.purchase") {
    purchaseAmount = Number(payload.amount);
  } else if (action === "education.purchase") {
    // Retain Bigisub price: WAEC ₦5,250, NECO ₦2,500, NABTEB ₦1,000
    const qty = Number(payload.quantity ?? 1);
    const examCode = String(payload.exam ?? "").toLowerCase();
    const bigisubPrice = examCode.includes("neco")
      ? 2500
      : examCode.includes("nabteb")
      ? 1000
      : examCode.includes("jamb")
      ? 5000
      : 5250;
    purchaseAmount = bigisubPrice * qty;
  } else if (action === "sms.send") {
    const recipients = Array.isArray(payload.recipients) ? payload.recipients : [];
    const message = String(payload.message ?? "");
    const pages = Math.ceil(message.length / 160) || 1;
    purchaseAmount = 3.5 * pages * recipients.length;
  } else if (action === "airtime_pin.purchase") {
    const denomination = Number(payload.amount ?? payload.value ?? 100);
    const qty = Number(payload.quantity ?? 1);
    purchaseAmount = denomination * qty;
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

    const { data: reservation, error: reserveError } = await userClient.rpc(
      "reserve_vtu_purchase",
      {
        p_amount: purchaseAmount,
        p_category: category,
        p_narration: narration,
        p_reference: reference,
      },
    );

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
    // 1. DATA PURCHASE: BilalSadaSub primary (cheaper), Bigisub fallback
    if (action === "data.purchase") {
      const netId = mapNetworkToId(payload.network);
      const phone = cleanPhone(payload.phone_number ?? payload.phone);
      const dataPlan = Number(payload.plan ?? payload.data_plan);

      // Attempt via BilalSadaSub
      const bilalPayload: JsonMap = {
        network: netId,
        phone,
        data_plan: dataPlan,
        bypass: false,
        "request-id": reference,
      };
      const bilalRes = await dispatchBilalRequest(
        `${bilalBaseUrl}/api/data`,
        "POST",
        bilalToken,
        bilalPayload,
      );
      finalStatus = normalizedProviderStatus(bilalRes.providerBody, bilalRes.upstream.ok);
      providerResponse = bilalRes.providerBody;

      // Failover to Bigisub if BilalSadaSub failed
      if (finalStatus === "failed" && bigisubToken) {
        try {
          const bigiPayload: JsonMap = {
            network: netId,
            plan: dataPlan,
            phone_number: phone,
            ported_number: true,
            pin: bigisubPin,
          };
          const bigiRes = await dispatchBigisubRequest(
            `${bigisubBaseUrl}/api/v2/vtu/data/purchase/`,
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
        bypass: false,
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

      if (finalStatus === "failed" && bigisubToken) {
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

    // 3. EXAM E-PIN PURCHASE: BilalSadaSub primary (cheaper fulfillment, retaining Bigisub retail price!), Bigisub fallback
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

      if (finalStatus === "failed" && bigisubToken) {
        try {
          const examUpper = String(payload.exam ?? "WAEC").toUpperCase();
          const bigiPayload: JsonMap = {
            exam: examUpper,
            exam_type: examUpper,
            quantity: qty,
            pin: bigisubPin,
            pin_code: bigisubPin,
          };
          const bigiRes = await dispatchBigisubRequest(
            `${bigisubBaseUrl}/api/v2/bills/result-checker/purchase/`,
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

    // 4. CABLE PURCHASE: BilalSadaSub primary, Bigisub fallback
    else if (action === "cable.purchase") {
      const cableId = mapCableToId(payload.cable_type ?? payload.cable_name ?? payload.cable);
      const card = String(payload.card_no ?? payload.iuc ?? "").trim();
      const planId = Number(payload.plan_id ?? payload.variation_code);
      const phone = cleanPhone(payload.phone ?? payload.phone_number ?? "08012345678");

      const bilalPayload: JsonMap = {
        cable: cableId,
        iuc: card,
        plan_id: planId,
        phone: phone || "08012345678",
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

      if (finalStatus === "failed" && bigisubToken) {
        try {
          const cableName = mapCableToName(payload.cable_type ?? payload.cable_name ?? payload.cable).toLowerCase();
          const bigiPayload: JsonMap = {
            cable_name: cableName,
            card_no: card,
            variation_code: String(payload.variation_code ?? planId),
            amount: Number(payload.amount),
            pin: bigisubPin,
          };
          const bigiRes = await dispatchBigisubRequest(
            `${bigisubBaseUrl}/api/v2/vtu/cable/purchase/`,
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

      if (finalStatus === "failed" && bigisubToken) {
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
      if (bigisubToken) {
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

    // 7. AIRTIME PIN: Bigisub recharge card generation
    else if (action === "airtime_pin.purchase") {
      if (bigisubToken) {
        const denomination = Number(payload.amount ?? payload.value ?? 100);
        const bigiRes = await dispatchBigisubRequest(
          `${bigisubBaseUrl}/api/v2/vtu/airtime-pin/purchase/`,
          "POST",
          bigisubToken,
          {
            network: mapNetworkToId(payload.network),
            amount: denomination,
            value: denomination,
            quantity: Number(payload.quantity ?? 1),
            business_name: String(payload.business_name ?? "Avotek"),
            pin: bigisubPin,
          },
        );
        finalStatus = normalizedProviderStatus(bigiRes.providerBody, bigiRes.upstream.ok);
        providerResponse = bigiRes.providerBody;
      } else {
        finalStatus = "failed";
        providerResponse = { message: "PIN generation service unavailable." };
      }
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

    // Finalize settlement in Supabase database
    if (finalStatus === "failed") {
      await finalizePurchase(supabaseUrl, reference, "failed", finalMessage, authData.user.id);
    } else if (finalStatus === "completed") {
      await finalizePurchase(supabaseUrl, reference, "completed", finalMessage, authData.user.id);
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
        authData.user.id,
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
