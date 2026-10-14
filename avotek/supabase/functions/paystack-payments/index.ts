import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-paystack-signature",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Origin": "*",
  "Content-Type": "application/json",
};

type JsonMap = Record<string, unknown>;

function jsonResponse(body: JsonMap, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: corsHeaders });
}

function isRecord(value: unknown): value is JsonMap {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function getServerConfig(): {
  supabaseUrl: string;
  serviceRoleKey: string;
  paystackSecretKey: string;
} | null {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const paystackSecretKey = Deno.env.get("PAYSTACK_SECRET_KEY");
  if (!supabaseUrl || !serviceRoleKey || !paystackSecretKey) return null;
  return { supabaseUrl, serviceRoleKey, paystackSecretKey };
}

async function createPaystackClient(
  supabaseUrl: string,
  serviceRoleKey: string,
) {
  return createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}

async function verifyPaystackTransaction(
  secretKey: string,
  reference: string,
): Promise<JsonMap> {
  const response = await fetch(
    `https://api.paystack.co/transaction/verify/${encodeURIComponent(reference)}`,
    {
      headers: { Authorization: `Bearer ${secretKey}` },
      signal: AbortSignal.timeout(15000),
    },
  );
  const body: unknown = await response.json();
  if (!response.ok || !isRecord(body) || body.status !== true || !isRecord(body.data)) {
    throw new Error("Paystack could not verify the payment at this time.");
  }
  return body.data;
}

async function sha512HmacHex(secret: string, value: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-512" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(value),
  );
  return [...new Uint8Array(signature)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function signaturesMatch(expected: string, supplied: string): boolean {
  if (!/^[a-f0-9]{128}$/i.test(supplied) || expected.length !== supplied.length) {
    return false;
  }
  let mismatch = 0;
  for (let index = 0; index < expected.length; index++) {
    mismatch |= expected.charCodeAt(index) ^ supplied.toLowerCase().charCodeAt(index);
  }
  return mismatch === 0;
}

async function handleWebhook(
  rawBody: string,
  suppliedSignature: string,
  config: NonNullable<ReturnType<typeof getServerConfig>>,
): Promise<Response> {
  const expectedSignature = await sha512HmacHex(config.paystackSecretKey, rawBody);
  if (!signaturesMatch(expectedSignature, suppliedSignature)) {
    return jsonResponse({ message: "Invalid webhook signature." }, 401);
  }

  let event: unknown;
  try {
    event = JSON.parse(rawBody);
  } catch {
    return jsonResponse({ message: "Invalid webhook body." }, 400);
  }
  if (!isRecord(event) || event.event !== "charge.success" || !isRecord(event.data)) {
    return jsonResponse({ received: true });
  }

  const reference = String(event.data.reference ?? "");
  if (!/^[A-Za-z0-9_-]{12,100}$/.test(reference)) {
    return jsonResponse({ message: "Invalid payment reference." }, 400);
  }

  const admin = await createPaystackClient(config.supabaseUrl, config.serviceRoleKey);
  const { data: transaction, error: transactionError } = await admin
    .from("transactions")
    .select("user_id, amount, status, category, type")
    .eq("reference", reference)
    .maybeSingle();
  if (transactionError) {
    console.error("Paystack webhook transaction lookup failed.");
    return jsonResponse({ message: "Payment record lookup failed." }, 503);
  }
  if (
    !transaction ||
    transaction.category !== "wallet_fund" ||
    transaction.type !== "credit"
  ) {
    console.error("Paystack webhook has no matching wallet funding record.");
    return jsonResponse({ message: "Payment reference was not recognized." }, 404);
  }
  if (transaction.status === "completed") return jsonResponse({ received: true });
  if (!["pending", "failed"].includes(transaction.status)) {
    return jsonResponse({ received: true });
  }

  let payment: JsonMap;
  try {
    payment = await verifyPaystackTransaction(config.paystackSecretKey, reference);
  } catch (error) {
    console.error("Paystack webhook verification request failed:", error);
    return jsonResponse({ message: "Payment verification is temporarily unavailable." }, 503);
  }

  const expectedKobo = Math.round(Number(transaction.amount) * 100);
  if (
    payment.reference !== reference ||
    payment.currency !== "NGN" ||
    Number(payment.amount) !== expectedKobo
  ) {
    console.error("Paystack verification details do not match the pending funding record.");
    return jsonResponse({ message: "Payment details did not match the funding record." }, 409);
  }
  if (payment.status !== "success") {
    return jsonResponse({ message: "Paystack has not confirmed this charge yet." }, 503);
  }

  const { error: creditError } = await admin.rpc("credit_paystack_wallet_funding", {
    p_user_id: transaction.user_id,
    p_reference: reference,
    p_amount: transaction.amount,
  });
  if (creditError) {
    console.error("Paystack webhook wallet credit failed:", creditError.message);
    return jsonResponse({ message: "Wallet credit is temporarily unavailable." }, 503);
  }
  return jsonResponse({ received: true });
}

async function authenticateUser(
  request: Request,
  supabaseUrl: string,
): Promise<{ id: string; email: string } | null> {
  const token = (request.headers.get("Authorization") ?? "")
    .replace(/^Bearer\s+/i, "")
    .trim();
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ??
    Deno.env.get("SUPABASE_PUBLISHABLE_KEY");
  if (!token || !anonKey) return null;

  const userClient = createClient(supabaseUrl, anonKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data, error } = await userClient.auth.getUser(token);
  if (error || !data.user?.email) return null;
  return { id: data.user.id, email: data.user.email };
}

async function handleInitialize(
  admin: Awaited<ReturnType<typeof createPaystackClient>>,
  config: NonNullable<ReturnType<typeof getServerConfig>>,
  user: { id: string; email: string },
  body: JsonMap,
): Promise<Response> {
  const amount = Number(body.amount);
  if (!Number.isInteger(amount) || amount < 100 || amount > 1000000) {
    return jsonResponse({ message: "Enter an amount between ₦100 and ₦1,000,000." }, 400);
  }

  const callbackUrl = Deno.env.get("PAYSTACK_CALLBACK_URL");
  if (!callbackUrl) {
    console.error("Paystack callback URL is not configured.");
    return jsonResponse({ message: "Wallet funding is not fully configured." }, 503);
  }
  let callback: URL;
  try {
    callback = new URL(callbackUrl);
    if (
      callback.protocol !== "https:" ||
      callback.hostname !== "adevictorolu.github.io" ||
      callback.pathname !== "/Avotek/"
    ) {
      throw new Error("Unexpected callback URL");
    }
  } catch {
    console.error("Paystack callback URL configuration is invalid.");
    return jsonResponse({ message: "Wallet funding is not fully configured." }, 503);
  }

  const reference = `AVOFUND_${crypto.randomUUID().replaceAll("-", "")}`;
  const { error: prepareError } = await admin.rpc("prepare_paystack_wallet_funding", {
    p_user_id: user.id,
    p_reference: reference,
    p_amount: amount,
  });
  if (prepareError) {
    console.error("Could not create pending wallet funding record:", prepareError.message);
    return jsonResponse({ message: "Could not start wallet funding. Please try again." }, 503);
  }

  let response: Response;
  try {
    response = await fetch("https://api.paystack.co/transaction/initialize", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${config.paystackSecretKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        email: user.email,
        amount: amount * 100,
        currency: "NGN",
        reference,
        callback_url: callback.toString(),
        metadata: { user_id: user.id, purpose: "wallet_funding" },
      }),
      signal: AbortSignal.timeout(15000),
    });
  } catch (error) {
    console.error("Paystack initialization request failed:", error);
    return jsonResponse({
      message: "Payment initialization could not be confirmed. Check your transactions before retrying.",
      reference,
    }, 503);
  }

  let result: unknown;
  try {
    result = await response.json();
  } catch (error) {
    console.error("Paystack initialization returned an unreadable response:", error);
    return jsonResponse({
      message: "Payment initialization could not be confirmed. Check your transactions before retrying.",
      reference,
    }, 502);
  }
  if (!response.ok || !isRecord(result) || result.status !== true || !isRecord(result.data)) {
    const { error } = await admin.rpc("fail_paystack_wallet_funding", {
      p_user_id: user.id,
      p_reference: reference,
    });
    if (error) console.error("Could not close failed Paystack initialization:", error.message);
    console.error("Paystack rejected payment initialization.");
    return jsonResponse({ message: "Paystack could not start this payment. Please try again." }, 502);
  }

  const authorizationUrl = result.data.authorization_url;
  let checkoutUrl: URL | null = null;
  try {
    if (typeof authorizationUrl === "string") checkoutUrl = new URL(authorizationUrl);
  } catch {
    checkoutUrl = null;
  }
  if (
    result.data.reference !== reference ||
    !checkoutUrl ||
    checkoutUrl.protocol !== "https:" ||
    checkoutUrl.hostname !== "checkout.paystack.com"
  ) {
    console.error("Paystack initialization returned an invalid checkout URL.");
    return jsonResponse({
      message: "Paystack returned an invalid checkout link. Check your transactions before retrying.",
      reference,
    }, 502);
  }
  return jsonResponse({ authorization_url: checkoutUrl.toString(), reference });
}

async function handleVerify(
  admin: Awaited<ReturnType<typeof createPaystackClient>>,
  config: NonNullable<ReturnType<typeof getServerConfig>>,
  user: { id: string; email: string },
  body: JsonMap,
): Promise<Response> {
  const reference = String(body.reference ?? "");
  if (!/^AVOFUND_[A-Fa-f0-9]{32}$/.test(reference)) {
    return jsonResponse({ message: "Invalid payment reference." }, 400);
  }

  const { data: transaction, error: transactionError } = await admin
    .from("transactions")
    .select("user_id, amount, status, category, type")
    .eq("reference", reference)
    .eq("user_id", user.id)
    .maybeSingle();
  if (transactionError) {
    console.error("Paystack verification record lookup failed:", transactionError.message);
    return jsonResponse({ message: "Could not check this payment right now." }, 503);
  }
  if (!transaction || transaction.category !== "wallet_fund" || transaction.type !== "credit") {
    return jsonResponse({ message: "Payment reference was not found." }, 404);
  }
  if (transaction.status === "completed") {
    return jsonResponse({ status: "completed", credited: false });
  }
  if (!["pending", "failed"].includes(transaction.status)) {
    return jsonResponse({ status: transaction.status, credited: false });
  }

  let payment: JsonMap;
  try {
    payment = await verifyPaystackTransaction(config.paystackSecretKey, reference);
  } catch (error) {
    console.error("Paystack transaction verification failed:", error);
    return jsonResponse({ message: "Payment is not confirmed yet. Please check again shortly." }, 503);
  }
  const expectedKobo = Math.round(Number(transaction.amount) * 100);
  if (
    payment.reference !== reference ||
    payment.currency !== "NGN" ||
    Number(payment.amount) !== expectedKobo
  ) {
    console.error("Paystack verification details do not match the pending funding record.");
    return jsonResponse({ message: "Payment details did not match the funding record." }, 409);
  }
  if (payment.status !== "success") {
    if (["failed", "abandoned", "reversed"].includes(String(payment.status))) {
      const { error } = await admin.rpc("fail_paystack_wallet_funding", {
        p_user_id: user.id,
        p_reference: reference,
      });
      if (error) {
        console.error("Could not mark failed Paystack payment:", error.message);
        return jsonResponse({ message: "Could not update payment status." }, 503);
      }
      return jsonResponse({ status: "failed", credited: false });
    }
    return jsonResponse({ status: "pending", credited: false });
  }

  const { error: creditError } = await admin.rpc("credit_paystack_wallet_funding", {
    p_user_id: user.id,
    p_reference: reference,
    p_amount: transaction.amount,
  });
  if (creditError) {
    console.error("Paystack verification wallet credit failed:", creditError.message);
    return jsonResponse({ message: "Payment is confirmed but wallet update is delayed." }, 503);
  }
  return jsonResponse({ status: "completed", credited: true });
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") {
    return jsonResponse({ message: "Method not allowed." }, 405);
  }

  const config = getServerConfig();
  if (!config) {
    console.error("Paystack function is missing server configuration.");
    return jsonResponse({ message: "Payment service is not configured." }, 503);
  }

  const rawBody = await request.text();
  if (rawBody.length > 20000) return jsonResponse({ message: "Request is too large." }, 413);

  if (request.headers.has("x-paystack-signature")) {
    return await handleWebhook(
      rawBody,
      request.headers.get("x-paystack-signature") ?? "",
      config,
    );
  }

  let body: unknown;
  try {
    body = JSON.parse(rawBody);
  } catch {
    return jsonResponse({ message: "Invalid request body." }, 400);
  }
  if (!isRecord(body)) return jsonResponse({ message: "Invalid request body." }, 400);

  const user = await authenticateUser(request, config.supabaseUrl);
  if (!user) return jsonResponse({ message: "Authentication is required." }, 401);
  const admin = await createPaystackClient(config.supabaseUrl, config.serviceRoleKey);

  if (body.action === "initialize") {
    return await handleInitialize(admin, config, user, body);
  }
  if (body.action === "verify") {
    return await handleVerify(admin, config, user, body);
  }
  return jsonResponse({ message: "Unsupported payment operation." }, 400);
});
