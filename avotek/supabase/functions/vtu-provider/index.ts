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
  "transaction.requery": { method: "GET", path: "" },
};

type JsonMap = Record<string, unknown>;

function jsonResponse(body: JsonMap, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: corsHeaders });
}

function isRecord(value: unknown): value is JsonMap {
  return typeof value === "object" && value !== null && !Array.isArray(value);
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
): "completed" | "failed" | "pending" {
  const data = isRecord(body.data) ? body.data : {};
  const raw = String(
    body.status ?? data.status ?? body.status_detail ?? data.status_detail ??
      "",
  ).trim().toLowerCase();
  if (
    body.success === false ||
    [
      "failed",
      "failure",
      "error",
      "rejected",
      "cancelled",
      "refunded",
      "partial",
    ].includes(raw)
  ) {
    return "failed";
  }
  if (
    ["pending", "processing", "submitted", "in_progress", "queued", "initiated"]
      .includes(raw)
  ) {
    return "pending";
  }
  if (
    body.success === true ||
    ["success", "successful", "completed"].includes(raw)
  ) {
    return "completed";
  }
  return "pending";
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
    const cable = String(payload.cable_name ?? "");
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
    const phone = String(payload.phone_number ?? "");
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
    const cable = String(payload.cable_type ?? payload.cable_name ?? "");
    if (!["dstv", "gotv", "startimes", "showmax"].includes(cable)) {
      throw new Error("Choose a valid cable provider.");
    }
    const card = String(payload.card_no ?? "");
    if (!/^\d{8,20}$/.test(card)) throw new Error("Enter a valid smartcard number.");
  }
  if (action === "cable.purchase" &&
    !/^[A-Za-z0-9_-]{1,100}$/.test(String(payload.variation_code ?? ""))) {
    throw new Error("Choose a valid cable package.");
  }
  if (action === "electricity.verify" || action === "electricity.purchase") {
    const meter = String(payload.meter_no ?? "");
    if (!/^\d{8,20}$/.test(meter)) throw new Error("Enter a valid meter number.");
    if (!["prepaid", "postpaid"].includes(String(payload.meter_type))) {
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

async function sha256Hex(value: string): Promise<string> {
  const bytes = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value));
  return [...new Uint8Array(bytes)].map((byte) => byte.toString(16).padStart(2, "0")).join("");
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

  const token = Deno.env.get("BIGISUB_API_TOKEN");
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
      const plans = isRecord(plansBody) && Array.isArray(plansBody.data)
        ? plansBody.data
        : [];
      const selectedPlan = plans.find((plan) =>
        isRecord(plan) && Number(plan.id) === Number(payload.plan)
      );
      const currentPlanPrice = isRecord(selectedPlan)
        ? Number(selectedPlan.amount ?? selectedPlan.plan_amount)
        : Number.NaN;
      if (
        !plansResponse.ok || !Number.isFinite(currentPlanPrice) ||
        currentPlanPrice <= 0
      ) {
        return jsonResponse({
          success: false,
          status: "failed",
          message: "The selected data plan is unavailable. Refresh plans and try again.",
        });
      }
      if (Number(payload.sell_price) !== currentPlanPrice) {
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
      const pricesData = isRecord(pricesBody) && isRecord(pricesBody.data)
        ? pricesBody.data
        : {};
      const prices = Array.isArray(pricesData.prices) ? pricesData.prices : [];
      const examCode = String(payload.exam).toLowerCase();
      const exam = prices.find((item) =>
        isRecord(item) &&
        String(item.code ?? item.exam_type ?? "").toLowerCase() === examCode
      );
      const unitPrice = isRecord(exam) ? Number(exam.amount) : Number.NaN;
      if (!pricesResponse.ok || !Number.isFinite(unitPrice) || unitPrice <= 0) {
        return jsonResponse({
          success: false,
          status: "failed",
          message: "The selected exam pin is unavailable. Refresh prices and try again.",
        });
      }
      purchaseAmount = unitPrice * Number(payload.quantity);
    } catch {
      return jsonResponse({
        success: false,
        status: "failed",
        message: "Could not verify the current exam pin price. Please try again.",
      });
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
        : {};
      const costPerPage = Number(pricingData.cost_per_page);
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

  if (action === "cable.purchase") {
    try {
      const cable = String(payload.cable_type ?? "");
      const plansResponse = await fetch(
        `${apiBaseUrl}/api/v2/vtu/cable/plans/?cable_name=${encodeURIComponent(cable)}`,
        {
          headers: { Authorization: `Token ${token}` },
          signal: AbortSignal.timeout(12000),
        },
      );
      const plansBody: unknown = await plansResponse.json();
      const plans = isRecord(plansBody) && Array.isArray(plansBody.data)
        ? plansBody.data
        : [];
      const selectedPlan = plans.find((plan) =>
        isRecord(plan) &&
        String(plan.variation_code ?? plan.id ?? "") === String(payload.variation_code)
      );
      const providerPrice = isRecord(selectedPlan)
        ? Number(selectedPlan.amount)
        : Number.NaN;
      if (!plansResponse.ok || !Number.isFinite(providerPrice) || providerPrice <= 0) {
        return jsonResponse({
          success: false,
          status: "failed",
          message: "The selected cable package is unavailable. Refresh packages and try again.",
        });
      }
      if (Number(payload.amount) < providerPrice) {
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

  if (config.purchase) {
    const aggregatorPin = Deno.env.get("BIGISUB_TRANSACTION_PIN");
    if (!aggregatorPin) {
      return jsonResponse({ message: "The service provider is not fully configured." }, 503);
    }
    const userPin = String(requestBody.user_pin ?? "");
    if (!/^\d{4}$/.test(userPin)) return jsonResponse({ message: "Enter your 4-digit transaction PIN." }, 400);

    const { data: profile, error: profileError } = await userClient
      .from("profiles")
      .select("transaction_pin_hash")
      .eq("id", authData.user.id)
      .maybeSingle();
    if (profileError || !profile?.transaction_pin_hash) {
      return jsonResponse({ message: "Set up your transaction PIN before purchasing." }, 400);
    }
    if (await sha256Hex(userPin) !== profile.transaction_pin_hash) {
      return jsonResponse({ message: "Invalid transaction PIN." }, 403);
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
    const transactionId = String(payload.transaction_id ?? "");
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
    if (!order || typeof order.provider_reference !== "string" ||
      !/^[A-Za-z0-9_-]{1,100}$/.test(order.provider_reference)) {
      return jsonResponse({
        message: "The provider reference is not available for this transaction.",
      }, 409);
    }
    requeryOrder = order;
    const providerTransactionId = order.provider_reference;
    path = order.service_type === "bulk_sms"
      ? `/api/v2/communications/sms/job/${encodeURIComponent(providerTransactionId)}/status/`
      : `/api/v2/anubis/transactions/${encodeURIComponent(providerTransactionId)}/requery/`;
  }

  if (config.purchase) {
    const amount = ["data.purchase", "education.purchase", "sms.send"].includes(action)
      ? purchaseAmount
      : Number(payload.amount);
    if (amount === null || !Number.isFinite(amount)) {
      return jsonResponse({
        success: false,
        status: "failed",
        message: "Could not verify the current data plan price. Refresh plans and try again.",
      }, 409);
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
        message: "This purchase request has already been processed.",
      });
    }
  }

  const providerPayload: JsonMap = { ...payload };
  delete providerPayload.sell_price;
  delete providerPayload.narration;
  if (config.purchase) {
    const aggregatorPin = Deno.env.get("BIGISUB_TRANSACTION_PIN")!;
    if (action === "education.purchase") {
      providerPayload.pin_code = aggregatorPin;
    } else {
      providerPayload.pin = aggregatorPin;
    }
  }

  try {
    const upstream = await fetch(`${apiBaseUrl}${path}${query}`, {
      method: config.method,
      headers: {
        Authorization: `Token ${token}`,
        "Content-Type": "application/json",
      },
      body: config.method === "GET" ? undefined : JSON.stringify(providerPayload),
      signal: AbortSignal.timeout(25000),
    });
    let providerBody: JsonMap = {};
    try {
      const parsed: unknown = await upstream.json();
      if (isRecord(parsed)) providerBody = parsed;
    } catch {
      providerBody = {};
    }

    if (config.purchase) {
      let status = normalizedProviderStatus(providerBody);
      let settlementMessage: string | null = null;
      if (action === "sms.send" && status === "completed") {
        const data = isRecord(providerBody.data) ? providerBody.data : {};
        const actualCost = Number(data.total_cost);
        if (!Number.isFinite(actualCost) || actualCost !== purchaseAmount) {
          status = "pending";
          settlementMessage =
            "SMS cost did not match the quote. The debit remains pending for reconciliation.";
        }
      }
      if (!upstream.ok && upstream.status < 500) status = "failed";
      if (!upstream.ok && upstream.status >= 500) status = "pending";
      if (status === "failed") {
        await finalizePurchase(
          supabaseUrl,
          reference,
          "failed",
          String(providerBody.message ?? "The provider rejected the purchase."),
          authData.user.id,
        );
      } else if (status === "completed") {
        await finalizePurchase(
          supabaseUrl,
          reference,
          "completed",
          String(providerBody.message ?? "Purchase completed."),
          authData.user.id,
        );
      }
      return jsonResponse({
        ...providerBody,
        success: status !== "failed",
        status,
        reference,
        local_reference: reference,
        charged_amount: reservedAmount,
        provider_reference: isRecord(providerBody.data)
          ? providerBody.data.transaction_id ?? providerBody.data.tran_id ??
            providerBody.data.tranx_id ?? providerBody.data.job_id ?? null
          : providerBody.transaction_id ?? providerBody.tran_id ??
            providerBody.tranx_id ?? providerBody.job_id ?? null,
        message: settlementMessage ?? String(providerBody.message ?? (status === "pending"
          ? "Provider response pending confirmation."
          : status === "failed"
          ? "The provider rejected the purchase."
          : "Purchase completed.")),
      });
    }

    if (action === "transaction.requery" && requeryOrder) {
      if (!upstream.ok) {
        return jsonResponse({
          message: String(providerBody.message ?? "Could not requery this transaction."),
        }, 502);
      }
      let status = normalizedProviderStatus(providerBody);
      let requeryMessage = String(
        providerBody.message ?? "Provider transaction status updated.",
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
          Number(transaction.amount) !== actualCost
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
          String(providerBody.message ?? "Provider transaction status updated."),
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
      return jsonResponse({ message: String(providerBody.message ?? "The provider request failed.") }, 502);
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
        message: "The provider response is delayed. Your purchase is pending confirmation.",
      });
    }
    return jsonResponse({ message: "Could not reach the service provider. Please try again." }, 502);
  }
});
