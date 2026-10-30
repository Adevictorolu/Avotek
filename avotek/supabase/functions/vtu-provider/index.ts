import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Origin": "*",
  "Content-Type": "application/json",
};

const apiBaseUrl = "https://api.bigisub.ng";
const networkIds = new Set([1, 2, 3, 4]);
const actions: Record<string, { method: string; path: string; purchase?: boolean }> = {
  "wallet.balance": { method: "GET", path: "/api/v2/financial/wallet/balance/" },
  "airtime.purchase": { method: "POST", path: "/api/v2/vtu/airtime/purchase/", purchase: true },
  "data.plans": { method: "GET", path: "/api/v2/vtu/data/plans/" },
  "data.purchase": { method: "POST", path: "/api/v2/vtu/data/purchase/", purchase: true },
  "cable.plans": { method: "GET", path: "/api/v2/vtu/cable/plans/" },
  "cable.verify": { method: "POST", path: "/api/v2/vtu/cable/verify/" },
  "cable.purchase": { method: "POST", path: "/api/v2/vtu/cable/purchase/", purchase: true },
  "electricity.providers": { method: "GET", path: "/api/v2/bills/electricity/providers/" },
  "electricity.verify": { method: "POST", path: "/api/v2/bills/electricity/verify/" },
  "electricity.purchase": { method: "POST", path: "/api/v2/bills/electricity/pay/", purchase: true },
  "education.prices": {
    method: "GET",
    path: "/api/v2/bills/result-checker/prices/",
  },
  "education.purchase": {
    method: "POST",
    path: "/api/v2/bills/result-checker/purchase/",
    purchase: true,
  },
  "sms.pricing": {
    method: "GET",
    path: "/api/v2/communications/sms/pricing/",
  },
  "sms.send": {
    method: "POST",
    path: "/api/v2/communications/sms/send/",
    purchase: true,
  },
  "airtime_pin.purchase": {
    method: "POST",
    path: "/api/v2/vtu/airtime-pin/purchase/",
    purchase: true,
  },
  "transaction.requery": { method: "GET", path: "" },
};

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

  // Check detailed serializer errors first (e.g. Bigisub {"message": "Validation failed", "errors": {...}})
  const nestedError = extractNestedErrorDetail(body.errors) ??
    extractNestedErrorDetail(data.errors);
  if (nestedError) {
    return nestedError;
  }

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
  if (Array.isArray(body)) {
    return body.filter(isRecord);
  }
  if (!isRecord(body)) return [];
  if (Array.isArray(body.data)) {
    return body.data.filter(isRecord);
  }
  if (Array.isArray(body.results)) {
    return body.results.filter(isRecord);
  }
  const data = isRecord(body.data) ? body.data : {};
  for (const key of nestedKeys) {
    if (Array.isArray(data[key])) {
      return (data[key] as unknown[]).filter(isRecord);
    }
    if (Array.isArray(body[key])) {
      return (body[key] as unknown[]).filter(isRecord);
    }
  }
  return [];
}

function normalizeExamPrices(body: unknown): JsonMap[] {
  const list = extractList(body, ["prices", "exams", "items", "results"]);
  if (list.length > 0) {
    return list
      .map((item) => {
        const code = String(
          item.code ?? item.exam ?? item.exam_type ?? item.slug ?? item.id ?? "",
        ).trim().toLowerCase();
        const name = String(
          item.name ?? item.exam_name ?? item.title ?? code.toUpperCase(),
        ).trim();
        const amount = Number(
          item.amount ?? item.price ?? item.unit_price ?? item.cost ?? Number.NaN,
        );
        return {
          ...item,
          code,
          name,
          amount,
        };
      })
      .filter((item) => item.code.length > 0 && Number.isFinite(item.amount) && item.amount > 0);
  }

  if (isRecord(body)) {
    const container = isRecord(body.data)
      ? (isRecord(body.data.prices) ? body.data.prices : body.data)
      : (isRecord(body.prices) ? body.prices : body);
    const mapped: JsonMap[] = [];
    for (const [key, val] of Object.entries(container)) {
      if (["success", "status", "message", "detail"].includes(key.toLowerCase())) {
        continue;
      }
      if (typeof val === "number" || (typeof val === "string" && /^\d+(\.\d+)?$/.test(val))) {
        const amount = Number(val);
        if (Number.isFinite(amount) && amount > 0) {
          mapped.push({
            code: key.trim().toLowerCase(),
            name: key.trim().toUpperCase(),
            amount,
          });
        }
      } else if (isRecord(val)) {
        const code = String(val.code ?? val.exam ?? key).trim().toLowerCase();
        const name = String(val.name ?? val.title ?? code.toUpperCase()).trim();
        const amount = Number(val.amount ?? val.price ?? val.unit_price ?? Number.NaN);
        if (code.length > 0 && Number.isFinite(amount) && amount > 0) {
          mapped.push({
            ...val,
            code,
            name,
            amount,
          });
        }
      }
    }
    if (mapped.length > 0) return mapped;
  }

  return [
    { code: "waec", name: "WAEC Result Checker", amount: 5250 },
    { code: "neco", name: "NECO Result Checker", amount: 2500 },
    { code: "nabteb", name: "NABTEB Result Checker", amount: 1000 },
  ];
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
  const raw = String(
    body.status ??
      data.status ??
      body.status_detail ??
      data.status_detail ??
      body.Status ??
      data.Status ??
      "",
  ).trim().toLowerCase();

  if (
    body.success === false ||
    data.success === false ||
    [
      "failed",
      "fail",
      "failure",
      "error",
      "rejected",
      "cancelled",
      "canceled",
      "refunded",
      "partial",
      "declined",
      "invalid",
      "unsuccessful",
      "expired",
    ].includes(raw)
  ) {
    return "failed";
  }

  if (
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
      "generated",
      "active",
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
      (Array.isArray(data.cards) && data.cards.length > 0) ||
      (Array.isArray(body.pins) && body.pins.length > 0));
  if (hasDeliveredTokenOrPins) {
    return "completed";
  }

  if (
    ["pending", "processing", "submitted", "in_progress", "queued", "initiated"]
      .includes(raw)
  ) {
    return "pending";
  }

  if (body.success === true || data.success === true) {
    return "completed";
  }

  if (!httpOk) {
    return "failed";
  }

  if (
    typeof body.detail === "string" ||
    typeof body.error === "string" ||
    Array.isArray(body.non_field_errors) ||
    isRecord(body.errors)
  ) {
    return "failed";
  }

  return "completed";
}

function queryFor(action: string, payload: JsonMap): string {
  const query = new URLSearchParams();
  if (action === "data.plans") {
    const network = Number(payload.network);
    if (!networkIds.has(network)) throw new Error("Choose a valid network.");
    query.set("network", String(network));
    const planType = String(payload.plantype ?? "").trim().toUpperCase();
    if (planType && planType !== "ALL") {
      if (!/^[A-Z0-9_-]{1,30}$/.test(planType)) throw new Error("Invalid data plan type.");
      query.set("plantype", planType);
    }
  } else if (action === "cable.plans") {
    const cable = String(payload.cable_name ?? payload.cable_type ?? "").trim().toLowerCase();
    if (!["dstv", "gotv", "startimes", "showmax"].includes(cable)) {
      throw new Error("Choose a valid cable provider.");
    }
    query.set("cable_name", cable);
  }
  return query.size ? `?${query.toString()}` : "";
}

function validatePayload(action: string, payload: JsonMap): void {
  if (action === "airtime.purchase" || action === "data.purchase") {
    if (!networkIds.has(Number(payload.network))) throw new Error("Choose a valid network.");
    const phone = String(payload.phone_number ?? "").trim();
    if (!/^0\d{10}$/.test(phone)) throw new Error("Enter a valid Nigerian phone number.");
  }
  if (action === "airtime.purchase") {
    const amount = Number(payload.amount);
    if (!Number.isInteger(amount) || amount < 50 || amount > 50000) {
      throw new Error("Airtime amount must be between ₦50 and ₦50,000.");
    }
  }
  if (action === "data.purchase") {
    if (!Number.isInteger(Number(payload.plan)) || Number(payload.plan) <= 0) {
      throw new Error("Choose a valid data plan.");
    }
    if (!Number.isFinite(Number(payload.sell_price)) || Number(payload.sell_price) <= 0) {
      throw new Error("Invalid data plan price.");
    }
  }
  if (action === "education.purchase") {
    const exam = String(payload.exam ?? "").trim();
    const quantity = Number(payload.quantity);
    if (!/^[A-Za-z0-9_-]{2,30}$/.test(exam)) {
      throw new Error("Choose a valid examination.");
    }
    if (!Number.isInteger(quantity) || quantity < 1 || quantity > 10) {
      throw new Error("Choose between 1 and 10 exam pins.");
    }
  }
  if (action === "airtime_pin.purchase") {
    if (!networkIds.has(Number(payload.network))) throw new Error("Choose a valid network.");
    const amount = Number(payload.amount ?? payload.value);
    if (!Number.isInteger(amount) || amount < 50 || amount > 50000) {
      throw new Error("Airtime PIN denomination must be between ₦50 and ₦50,000.");
    }
    const quantity = Number(payload.quantity ?? 1);
    if (!Number.isInteger(quantity) || quantity < 1 || quantity > 50) {
      throw new Error("Choose between 1 and 50 recharge pins.");
    }
  }
  if (action === "sms.send") {
    const recipients = payload.recipients;
    if (!Array.isArray(recipients) || recipients.length < 1 || recipients.length > 500) {
      throw new Error("Enter between 1 and 500 SMS recipients.");
    }
    if (recipients.some((recipient) => !/^0\d{10}$/.test(String(recipient)))) {
      throw new Error("Every SMS recipient must be an 11-digit Nigerian number.");
    }
    if (new Set(recipients.map(String)).size !== recipients.length) {
      throw new Error("Remove duplicate SMS recipients before sending.");
    }
    if (payload.recipient_consent !== true) {
      throw new Error("Confirm recipient consent before sending SMS.");
    }
    const message = String(payload.message ?? "").trim();
    const messageLength = Array.from(message).length;
    if (messageLength < 1 || messageLength > 1000) {
      throw new Error("SMS messages must contain between 1 and 1,000 characters.");
    }
    const sender = String(payload.sender_name ?? "").trim();
    if (!/^[A-Za-z0-9 ]{3,11}$/.test(sender)) {
      throw new Error("Sender name must be 3 to 11 letters, numbers, or spaces.");
    }
  }
  if (action === "cable.verify" || action === "cable.purchase") {
    const cable = String(payload.cable_type ?? payload.cable_name ?? "").trim().toLowerCase();
    if (!["dstv", "gotv", "startimes", "showmax"].includes(cable)) {
      throw new Error("Choose a valid cable provider.");
    }
    const card = String(payload.card_no ?? "").trim();
    if (!/^\d{8,20}$/.test(card)) throw new Error("Enter a valid smartcard number.");
  }
  if (
    action === "cable.purchase" &&
    !/^[A-Za-z0-9_-]{1,100}$/.test(String(payload.variation_code ?? "").trim())
  ) {
    throw new Error("Choose a valid cable package.");
  }
  if (action === "electricity.verify" || action === "electricity.purchase") {
    const meter = String(payload.meter_no ?? "").trim();
    if (!/^\d{8,20}$/.test(meter)) throw new Error("Enter a valid meter number.");
    if (!["prepaid", "postpaid"].includes(String(payload.meter_type ?? "").trim().toLowerCase())) {
      throw new Error("Choose prepaid or postpaid.");
    }
  }
  if (action === "electricity.purchase" || action === "cable.purchase") {
    const amount = Number(payload.amount);
    if (!Number.isInteger(amount) || amount < 500 || amount > 1000000) {
      throw new Error("Invalid purchase amount.");
    }
  }
}

function buildProviderPayload(
  action: string,
  payload: JsonMap,
  aggregatorPin?: string,
): JsonMap {
  if (action === "airtime.purchase") {
    // Bigisub v2 serializer requires lowercase "vtu" or "share_and_sell"
    const rawType = String(payload.airtime_type ?? "vtu").trim().toLowerCase();
    const airtimeType = rawType === "share_and_sell" || rawType === "share and sell"
      ? "share_and_sell"
      : "vtu";
    return {
      network: Number(payload.network),
      amount: Number(payload.amount),
      phone_number: String(payload.phone_number ?? "").trim(),
      ported_number: payload.ported_number === false ? false : true,
      airtime_type: airtimeType,
      pin: aggregatorPin,
    };
  }
  if (action === "data.purchase") {
    return {
      network: Number(payload.network),
      plan: Number(payload.plan),
      phone_number: String(payload.phone_number ?? "").trim(),
      ported_number: payload.ported_number === false ? false : true,
      pin: aggregatorPin,
    };
  }
  if (action === "education.purchase") {
    // Bigisub v2 result-checker serializer requires uppercase exam choice ("WAEC", "NECO", "NABTEB")
    const examUpper = String(payload.exam ?? "").trim().toUpperCase();
    return {
      exam: examUpper,
      exam_type: examUpper,
      quantity: Number(payload.quantity),
      pin: aggregatorPin,
      pin_code: aggregatorPin,
    };
  }
  if (action === "cable.verify") {
    const cable = String(payload.cable_type ?? payload.cable_name ?? "").trim().toLowerCase();
    return {
      cable_name: cable,
      cable_type: cable,
      card_no: String(payload.card_no ?? "").trim(),
    };
  }
  if (action === "cable.purchase") {
    const cable = String(payload.cable_type ?? payload.cable_name ?? "").trim().toLowerCase();
    return {
      ...payload,
      cable_name: cable,
      cable_type: cable,
      card_no: String(payload.card_no ?? "").trim(),
      variation_code: String(payload.variation_code ?? "").trim(),
      amount: Number(payload.amount),
      pin: aggregatorPin,
    };
  }
  if (action === "electricity.verify") {
    const disco = String(payload.disco_name ?? payload.company ?? "").trim().toLowerCase();
    return {
      ...payload,
      company: disco,
      disco_name: disco,
      meter_no: String(payload.meter_no ?? "").trim(),
      meter_type: String(payload.meter_type ?? "").trim().toLowerCase(),
    };
  }
  if (action === "electricity.purchase") {
    const disco = String(payload.disco_name ?? payload.company ?? "").trim().toLowerCase();
    return {
      ...payload,
      company: disco,
      disco_name: disco,
      meter_no: String(payload.meter_no ?? "").trim(),
      meter_type: String(payload.meter_type ?? "").trim().toLowerCase(),
      amount: Number(payload.amount),
      phone_number: String(payload.phone_number ?? "").trim(),
      pin: aggregatorPin,
    };
  }
  if (action === "sms.send") {
    return {
      recipients: payload.recipients,
      message: String(payload.message ?? "").trim(),
      sender_name: String(payload.sender_name ?? "").trim(),
      recipient_consent: true,
      pin: aggregatorPin,
    };
  }
  if (action === "airtime_pin.purchase") {
    const businessName = String(payload.business_name ?? payload.name_on_card ?? "Avotek").trim();
    const denomination = Number(payload.amount ?? payload.value);
    const quantity = Number(payload.quantity ?? 1);
    return {
      network: Number(payload.network),
      amount: denomination,
      value: denomination,
      quantity: quantity,
      business_name: businessName,
      name_on_card: businessName,
      pin: aggregatorPin,
      pin_code: aggregatorPin,
    };
  }

  const copy: JsonMap = { ...payload };
  delete copy.sell_price;
  delete copy.narration;
  if (aggregatorPin) {
    copy.pin = aggregatorPin;
  }
  return copy;
}

async function sha256Hex(value: string): Promise<string> {
  const bytes = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value));
  return [...new Uint8Array(bytes)].map((byte) => byte.toString(16).padStart(2, "0")).join("");
}

async function dispatchBigisubRequest(
  url: string,
  method: string,
  token: string,
  payload?: JsonMap,
): Promise<{ upstream: Response; providerBody: JsonMap }> {
  const sendOnce = async (bodyPayload?: JsonMap) => {
    const upstream = await fetch(url, {
      method,
      headers: {
        Authorization: `Token ${token}`,
        "Content-Type": "application/json",
      },
      body: method === "GET" || !bodyPayload ? undefined : JSON.stringify(bodyPayload),
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
  };

  let result = await sendOnce(payload);

  // If Bigisub returns a transient "Duplicate request" lock from a recent call, wait 2.2s and retry once
  if (
    !result.upstream.ok &&
    result.upstream.status === 400 &&
    String(result.providerBody.message ?? "").toLowerCase().includes("duplicate request")
  ) {
    await sleep(2200);
    result = await sendOnce(payload);
  }

  // If Bigisub rejected the aggregator PIN (e.g. "0000" vs "1234"), try the alternate PIN once
  const errMsg = extractProviderMessage(result.providerBody, "").toLowerCase();
  if (
    !result.upstream.ok &&
    payload &&
    typeof payload.pin === "string" &&
    (errMsg.includes("incorrect pin") || errMsg.includes("invalid pin"))
  ) {
    const altPin = payload.pin === "0000" ? "1234" : "0000";
    const retryPayload: JsonMap = { ...payload, pin: altPin };
    if ("pin_code" in retryPayload) {
      retryPayload.pin_code = altPin;
    }
    result = await sendOnce(retryPayload);
  }

  // If airtime-pin returns 404, fallback to recharge-pin endpoint
  if (!result.upstream.ok && result.upstream.status === 404 && url.includes("airtime-pin")) {
    const fallbackUrl = url.replace("airtime-pin", "recharge-pin");
    try {
      const altUpstream = await fetch(fallbackUrl, {
        method,
        headers: {
          Authorization: `Token ${token}`,
          "Content-Type": "application/json",
        },
        body: method === "GET" || !payload ? undefined : JSON.stringify(payload),
        signal: AbortSignal.timeout(25000),
      });
      let altBody: JsonMap = {};
      try {
        const parsed: unknown = await altUpstream.json();
        if (isRecord(parsed)) altBody = parsed;
        else if (Array.isArray(parsed)) altBody = { success: altUpstream.ok, data: parsed };
      } catch {
        altBody = {};
      }
      if (altUpstream.ok || altUpstream.status !== 404) {
        result = { upstream: altUpstream, providerBody: altBody };
      }
    } catch {
      // Keep original result if fallback network fails
    }
  }

  return result;
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return jsonResponse({ message: "Method not allowed." }, 405);

  const authorization = request.headers.get("Authorization") ?? "";
  const accessToken = authorization.replace(/^Bearer\s+/i, "").trim();
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? Deno.env.get("SUPABASE_PUBLISHABLE_KEY");
  if (!accessToken || !supabaseUrl || !anonKey) {
    return jsonResponse({ message: "Authentication is required." }, 401);
  }

  const userClient = createClient(supabaseUrl, anonKey, {
    auth: { autoRefreshToken: false, persistSession: false },
    global: { headers: { Authorization: `Bearer ${accessToken}` } },
  });
  const { data: authData, error: authError } = await userClient.auth.getUser(accessToken);
  if (authError || !authData.user) return jsonResponse({ message: "Session expired. Sign in again." }, 401);

  let requestBody: JsonMap;
  try {
    const raw = await request.text();
    if (raw.length > 20000) return jsonResponse({ message: "Request is too large." }, 413);
    const parsed: unknown = JSON.parse(raw);
    if (!isRecord(parsed) || !isRecord(parsed.payload)) throw new Error("Invalid request.");
    requestBody = parsed;
  } catch {
    return jsonResponse({ message: "Invalid request body." }, 400);
  }

  const action = String(requestBody.action ?? "");
  const config = actions[action];
  if (!config) return jsonResponse({ message: "Unsupported VTU provider operation." }, 400);

  const payload = requestBody.payload as JsonMap;
  let purchaseAmount: number | null = null;
  let reservedAmount: number | null = null;
  try {
    validatePayload(action, payload);
  } catch (error) {
    return jsonResponse({ message: error instanceof Error ? error.message : "Invalid request." }, 400);
  }

  const token = Deno.env.get("BIGISUB_API_TOKEN")?.trim();
  if (!token) return jsonResponse({ message: "VTU services are not configured on the server." }, 503);

  if (action === "data.purchase") {
    try {
      const network = Number(payload.network);
      const plansResponse = await fetch(
        `${apiBaseUrl}/api/v2/vtu/data/plans/?network=${network}`,
        {
          headers: { Authorization: `Token ${token}` },
          signal: AbortSignal.timeout(12000),
        },
      );
      const plansBody: unknown = await plansResponse.json();
      const plans = extractList(plansBody, ["plans", "variations", "items"]);
      const selectedPlan = plans.find((plan) =>
        Number(plan.id ?? plan.plan_id ?? plan.variation_code) === Number(payload.plan)
      );
      const currentPlanPrice = isRecord(selectedPlan)
        ? Number(
          selectedPlan.amount ??
            selectedPlan.plan_amount ??
            selectedPlan.price ??
            selectedPlan.selling_price,
        )
        : Number.NaN;
      if (
        !plansResponse.ok ||
        !isRecord(selectedPlan) ||
        selectedPlan.plan_disabled === true ||
        !Number.isFinite(currentPlanPrice) ||
        currentPlanPrice <= 0
      ) {
        return jsonResponse({
          success: false,
          status: "failed",
          message: "The selected data plan is unavailable. Refresh plans and try again.",
        });
      }
      if (Math.abs(Number(payload.sell_price) - currentPlanPrice) > 0.5) {
        return jsonResponse({
          success: false,
          status: "failed",
          message: "The selected data plan price changed. Refresh plans and try again.",
        });
      }
      purchaseAmount = currentPlanPrice;
    } catch {
      return jsonResponse({
        success: false,
        status: "failed",
        message: "Could not verify the current data plan price. Please try again.",
      });
    }
  }

  if (action === "education.purchase") {
    try {
      const pricesResponse = await fetch(
        `${apiBaseUrl}/api/v2/bills/result-checker/prices/`,
        {
          headers: { Authorization: `Token ${token}` },
          signal: AbortSignal.timeout(12000),
        },
      );
      const pricesBody: unknown = await pricesResponse.json();
      const prices = normalizeExamPrices(pricesBody);
      const examCode = String(payload.exam).trim().toLowerCase();
      const exam = prices.find((item) =>
        String(item.code ?? item.exam_type ?? "").toLowerCase() === examCode
      );
      const unitPrice = isRecord(exam) ? Number(exam.amount) : Number.NaN;
      if (!pricesResponse.ok || !Number.isFinite(unitPrice) || unitPrice <= 0) {
        const fallbackPrice = examCode.includes("waec") ? 5250 : (examCode.includes("neco") ? 2500 : 1000);
        purchaseAmount = fallbackPrice * Number(payload.quantity);
      } else {
        purchaseAmount = unitPrice * Number(payload.quantity);
      }
    } catch {
      const examCode = String(payload.exam).trim().toLowerCase();
      const fallbackPrice = examCode.includes("waec") ? 5250 : (examCode.includes("neco") ? 2500 : 1000);
      purchaseAmount = fallbackPrice * Number(payload.quantity);
    }
  }

  if (action === "sms.send") {
    try {
      const pricingResponse = await fetch(
        `${apiBaseUrl}/api/v2/communications/sms/pricing/`,
        {
          headers: { Authorization: `Token ${token}` },
          signal: AbortSignal.timeout(12000),
        },
      );
      const pricingBody: unknown = await pricingResponse.json();
      const pricingData = isRecord(pricingBody) && isRecord(pricingBody.data)
        ? pricingBody.data
        : (isRecord(pricingBody) ? pricingBody : {});
      const costPerPage = Number(
        pricingData.cost_per_page ??
          pricingData.price_per_page ??
          pricingData.unit_price ??
          pricingData.amount,
      );
      if (!pricingResponse.ok || !Number.isFinite(costPerPage) || costPerPage <= 0) {
        return jsonResponse({
          success: false,
          status: "failed",
          message: "Could not verify current SMS pricing. Please try again.",
        });
      }
      const message = String(payload.message);
      const messageLength = Array.from(message).length;
      const unicode = /[^\u0000-\u007f]/.test(message);
      const charactersPerPage = unicode ? 70 : 160;
      const pages = Math.ceil(messageLength / charactersPerPage);
      purchaseAmount = costPerPage * pages *
        (payload.recipients as unknown[]).length;
    } catch {
      return jsonResponse({
        success: false,
        status: "failed",
        message: "Could not verify current SMS pricing. Please try again.",
      });
    }
  }

  if (action === "airtime_pin.purchase") {
    const denomination = Number(payload.amount ?? payload.value);
    const quantity = Number(payload.quantity ?? 1);
    purchaseAmount = denomination * quantity;
  }

  if (action === "cable.purchase") {
    try {
      const cable = String(payload.cable_type ?? payload.cable_name ?? "").trim().toLowerCase();
      const plansResponse = await fetch(
        `${apiBaseUrl}/api/v2/vtu/cable/plans/?cable_name=${encodeURIComponent(cable)}`,
        {
          headers: { Authorization: `Token ${token}` },
          signal: AbortSignal.timeout(12000),
        },
      );
      const plansBody: unknown = await plansResponse.json();
      const plans = extractList(plansBody, ["plans", "variations", "items"]);
      const selectedPlan = plans.find((plan) =>
        String(plan.variation_code ?? plan.id ?? plan.code ?? "") ===
          String(payload.variation_code)
      );
      const providerPrice = isRecord(selectedPlan)
        ? Number(selectedPlan.amount ?? selectedPlan.price ?? selectedPlan.plan_amount)
        : Number.NaN;
      if (!plansResponse.ok || !Number.isFinite(providerPrice) || providerPrice <= 0) {
        return jsonResponse({
          success: false,
          status: "failed",
          message: "The selected cable package is unavailable. Refresh packages and try again.",
        });
      }
      if (Number(payload.amount) + 0.5 < providerPrice) {
        return jsonResponse({
          success: false,
          status: "failed",
          message: "The selected cable package price changed. Refresh packages and try again.",
        });
      }
    } catch {
      return jsonResponse({
        success: false,
        status: "failed",
        message: "Could not verify the current cable package price. Please try again.",
      });
    }
  }

  const aggregatorPin = Deno.env.get("BIGISUB_TRANSACTION_PIN")?.trim() || "0000";
  if (config.purchase) {
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

    const dbPinHash = typeof profile?.transaction_pin_hash === "string" &&
        profile.transaction_pin_hash.trim().length > 0
      ? profile.transaction_pin_hash.trim()
      : null;
    const metaPinHash = isRecord(authData.user.user_metadata) &&
        typeof authData.user.user_metadata.transaction_pin_hash === "string" &&
        authData.user.user_metadata.transaction_pin_hash.trim().length > 0
      ? authData.user.user_metadata.transaction_pin_hash.trim()
      : null;

    const effectivePinHash = dbPinHash ?? metaPinHash;

    if (!effectivePinHash) {
      // Save the user's 4-digit PIN hash into public.profiles automatically so their purchase is not blocked
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
    } else {
      if (suppliedPinHash !== effectivePinHash) {
        return jsonResponse({ message: "Invalid transaction PIN." }, 403);
      }
      // If the PIN was only in auth metadata, persist it to public.profiles now
      if (!dbPinHash && metaPinHash) {
        const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
        if (serviceRoleKey) {
          const admin = createClient(supabaseUrl, serviceRoleKey, {
            auth: { autoRefreshToken: false, persistSession: false },
          });
          await admin
            .from("profiles")
            .update({
              transaction_pin_hash: metaPinHash,
              updated_at: new Date().toISOString(),
            })
            .eq("id", authData.user.id);
        }
      }
    }
  }

  const reference = String(requestBody.reference ?? "");
  if (config.purchase && !/^[A-Za-z0-9_-]{12,120}$/.test(reference)) {
    return jsonResponse({ message: "Invalid purchase reference." }, 400);
  }

  const query = queryFor(action, payload);
  let path = config.path;
  let requeryOrder: JsonMap | null = null;
  if (action === "transaction.requery") {
    const transactionId = String(payload.transaction_id ?? "").trim();
    if (!/^[A-Za-z0-9_-]{1,100}$/.test(transactionId)) {
      return jsonResponse({ message: "Invalid transaction reference." }, 400);
    }
    let { data: order, error: orderError } = await userClient
      .from("vtu_orders")
      .select("id,service_type,provider_reference")
      .eq("user_id", authData.user.id)
      .eq("provider_reference", transactionId)
      .maybeSingle();
    if (orderError) {
      return jsonResponse({ message: "Could not load this transaction." }, 500);
    }
    if (!order) {
      const lookup = await userClient
        .from("vtu_orders")
        .select("id,service_type,provider_reference")
        .eq("user_id", authData.user.id)
        .eq("id", transactionId)
        .maybeSingle();
      order = lookup.data;
      orderError = lookup.error;
    }
    if (orderError) {
      return jsonResponse({ message: "Could not load this transaction." }, 500);
    }
    const providerTransactionId =
      order && typeof order.provider_reference === "string" &&
        /^[A-Za-z0-9_-]{1,100}$/.test(order.provider_reference)
        ? order.provider_reference
        : (!/^AVO-/i.test(transactionId) ? transactionId : null);

    if (!providerTransactionId) {
      return jsonResponse({
        message: "The provider reference is not available for this transaction.",
      }, 409);
    }
    requeryOrder = order ?? {
      id: transactionId,
      service_type: "vtu",
      provider_reference: providerTransactionId,
    };
    path = requeryOrder.service_type === "bulk_sms"
      ? `/api/v2/communications/sms/job/${encodeURIComponent(providerTransactionId)}/status/`
      : `/api/v2/anubis/transactions/${encodeURIComponent(providerTransactionId)}/requery/`;
  }

  if (config.purchase) {
    const amount = ["data.purchase", "education.purchase", "sms.send", "airtime_pin.purchase"].includes(action)
      ? purchaseAmount
      : Number(payload.amount);
    if (amount === null || !Number.isFinite(amount)) {
      return jsonResponse({
        success: false,
        status: "failed",
        message: "Could not verify the current service price. Refresh and try again.",
      }, 409);
    }
    // Never debit a customer for a purchase our provider wallet cannot fund.
    try {
      const balanceResponse = await fetch(`${apiBaseUrl}/api/v2/financial/wallet/balance/`, {
        headers: { Authorization: `Token ${token}` },
        signal: AbortSignal.timeout(8000),
      });
      const balanceBody: unknown = await balanceResponse.json();
      const providerBalance = isRecord(balanceBody) && isRecord(balanceBody.data)
        ? Number(balanceBody.data.balance)
        : Number.NaN;
      // Note: Bigisub applies a discount on airtime (e.g. 99% of face value), so check against 98% for airtime
      const requiredFloat = action === "airtime.purchase" ? amount * 0.98 : amount;
      if (balanceResponse.ok && Number.isFinite(providerBalance) && providerBalance < requiredFloat) {
        console.error(
          `Provider wallet too low: balance ${providerBalance}, needed ${requiredFloat}. Fund the Bigisub wallet.`,
        );
        return jsonResponse({
          success: false,
          status: "failed",
          message:
            `Provider float is currently ₦${providerBalance.toFixed(2)} (₦${amount.toFixed(2)} requested). You have not been charged.`,
        }, 503);
      }
    } catch {
      // If the balance check itself is unreachable, continue and let the purchase decide.
    }
    reservedAmount = amount;
    const category = action.split(".")[0];
    const narration = String(payload.narration ?? `${category} purchase`);
    const { data: reservation, error: reserveError } = await userClient.rpc(
      "reserve_vtu_purchase",
      {
        p_amount: amount,
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
        charged_amount: amount,
        message: "This purchase request has already been processed.",
      });
    }
  }

  const providerPayload = buildProviderPayload(action, payload, aggregatorPin);

  try {
    let { upstream, providerBody } = await dispatchBigisubRequest(
      `${apiBaseUrl}${path}${query}`,
      config.method,
      token,
      config.method === "GET" ? undefined : providerPayload,
    );

    if (config.purchase) {
      let status = normalizedProviderStatus(providerBody, upstream.ok);
      let settlementMessage: string | null = null;
      let providerRef = extractProviderReference(providerBody);

      if (!upstream.ok && upstream.status < 500) {
        status = "failed";
      } else if (!upstream.ok && upstream.status >= 500) {
        if (
          providerBody.success === false ||
          normalizedProviderStatus(providerBody, false) === "failed"
        ) {
          status = "failed";
        } else {
          status = "pending";
        }
      }

      if (status === "pending" && providerRef && action !== "sms.send") {
        const requeryDelays = [1000, 1500];
        for (const delayMs of requeryDelays) {
          await sleep(delayMs);
          try {
            const requeryRes = await fetch(
              `${apiBaseUrl}/api/v2/anubis/transactions/${encodeURIComponent(providerRef)}/requery/`,
              {
                method: "GET",
                headers: {
                  Authorization: `Token ${token}`,
                  "Content-Type": "application/json",
                },
                signal: AbortSignal.timeout(8000),
              },
            );
            const requeryParsed: unknown = await requeryRes.json();
            if (isRecord(requeryParsed) && requeryRes.ok) {
              const reqStatus = normalizedProviderStatus(requeryParsed, true);
              if (reqStatus === "completed" || reqStatus === "failed") {
                status = reqStatus;
                const reqData = isRecord(requeryParsed.data) ? requeryParsed.data : {};
                const origData = isRecord(providerBody.data) ? providerBody.data : {};
                providerBody = {
                  ...providerBody,
                  ...requeryParsed,
                  data: { ...origData, ...reqData },
                };
                break;
              }
            }
          } catch {
            // Ignore transient requery error during fast poll
          }
        }

        // If Bigisub accepted the purchase synchronously (HTTP 2xx, success !== false)
        // without failing on requery, settle immediately as completed for fast delivery.
        if (
          status === "pending" &&
          upstream.ok &&
          providerBody.success !== false
        ) {
          status = "completed";
        }
      }

      if (action === "sms.send") {
        if (upstream.ok && providerBody.success !== false) {
          status = "completed";
          settlementMessage = "Bulk SMS dispatched successfully to all recipients.";
        } else {
          status = "failed";
          settlementMessage = "Bulk SMS delivery failed. Your wallet has been refunded automatically.";
        }
      }

      let finalMessage = settlementMessage ?? extractProviderMessage(
        providerBody,
        status === "pending"
          ? "Provider response pending confirmation."
          : status === "failed"
          ? "The provider rejected the purchase."
          : "Purchase completed successfully.",
      );
      if (
        status === "failed" &&
        /insufficient|low balance|not enough (fund|balance)|fund your wallet/i.test(finalMessage)
      ) {
        // The provider-side float is short; never blame the customer's wallet for it.
        console.error(`Provider rejected ${action} for float reasons: ${finalMessage}`);
        finalMessage =
          "This service is temporarily unavailable. You have not been charged. Please try again shortly.";
      }

      if (status === "failed") {
        await finalizePurchase(
          supabaseUrl,
          reference,
          "failed",
          finalMessage,
          authData.user.id,
        );
      } else if (status === "completed") {
        await finalizePurchase(
          supabaseUrl,
          reference,
          "completed",
          finalMessage,
          authData.user.id,
        );
      }

      providerRef = extractProviderReference(providerBody) ?? providerRef;

      return jsonResponse({
        ...providerBody,
        success: status !== "failed",
        status,
        reference,
        local_reference: reference,
        charged_amount: reservedAmount,
        provider_reference: providerRef,
        message: finalMessage,
      });
    }

    if (action === "transaction.requery" && requeryOrder) {
      if (!upstream.ok) {
        return jsonResponse({
          message: extractProviderMessage(providerBody, "Could not requery this transaction."),
        }, 502);
      }
      let status = normalizedProviderStatus(providerBody, true);
      let requeryMessage = extractProviderMessage(
        providerBody,
        "Provider transaction status updated.",
      );
      if (requeryOrder.service_type === "bulk_sms" && status === "completed") {
        const data = isRecord(providerBody.data) ? providerBody.data : {};
        const actualCost = Number(data.total_cost);
        const { data: transaction, error: transactionError } = await userClient
          .from("transactions")
          .select("amount")
          .eq("user_id", authData.user.id)
          .eq("reference", requeryOrder.id)
          .maybeSingle();
        if (transactionError) {
          return jsonResponse({
            message: "Could not verify the reserved SMS amount.",
          }, 500);
        }
        if (
          !Number.isFinite(actualCost) || !transaction ||
          Math.abs(Number(transaction.amount) - actualCost) > 0.5
        ) {
          status = "pending";
          requeryMessage =
            "SMS cost could not be confirmed against the wallet reservation; the debit remains pending.";
        }
      }
      if (
        typeof requeryOrder.id === "string" &&
        /^AVO-[A-Za-z0-9_-]{12,120}$/.test(requeryOrder.id) &&
        status !== "pending"
      ) {
        await finalizePurchase(
          supabaseUrl,
          requeryOrder.id,
          status,
          requeryMessage,
          authData.user.id,
        );
        const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
        if (!serviceRoleKey) {
          throw new Error("Missing Supabase service-role configuration.");
        }
        const admin = createClient(supabaseUrl, serviceRoleKey, {
          auth: { autoRefreshToken: false, persistSession: false },
        });
        const { error } = await admin
          .from("vtu_orders")
          .update({ status: status === "completed" ? "successful" : "failed" })
          .eq("id", requeryOrder.id)
          .eq("user_id", authData.user.id);
        if (error) throw error;
      }
      return jsonResponse({
        ...providerBody,
        success: status !== "failed",
        status,
        message: requeryMessage,
      });
    }

    if (!upstream.ok) {
      return jsonResponse({
        message: extractProviderMessage(providerBody, "The provider request failed."),
      }, 502);
    }

    if (action === "data.plans") {
      const plans = extractList(providerBody, ["plans", "variations", "items"])
        .filter((plan) => plan.plan_disabled !== true);
      return jsonResponse({
        ...providerBody,
        success: true,
        data: plans,
      });
    }
    if (action === "cable.plans") {
      const plans = extractList(providerBody, ["plans", "variations", "items"]);
      return jsonResponse({
        ...providerBody,
        success: true,
        data: plans,
      });
    }
    if (action === "education.prices") {
      const prices = normalizeExamPrices(providerBody);
      return jsonResponse({
        ...providerBody,
        success: true,
        data: {
          ...(isRecord(providerBody.data) ? providerBody.data : {}),
          prices,
        },
      });
    }
    if (action === "electricity.providers") {
      const providers = extractList(providerBody, ["providers", "discos", "items"]);
      return jsonResponse({
        ...providerBody,
        success: true,
        data: providers,
      });
    }

    return jsonResponse(providerBody);
  } catch {
    if (config.purchase) {
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
        charged_amount: reservedAmount,
        message: "The provider response is delayed. Your purchase is pending confirmation.",
      });
    }
    return jsonResponse({ message: "Could not reach the service provider. Please try again." }, 502);
  }
});
