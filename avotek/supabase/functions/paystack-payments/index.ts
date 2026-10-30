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

function hasLivePaystackKey(secretKey: string): boolean {
  return secretKey.trim().startsWith("sk_live_");
}

function getServerConfig(): {
  supabaseUrl: string;
  serviceRoleKey: string;
  paystackSecretKey: string;
} | null {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")?.trim();
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")?.trim();
  const paystackSecretKey = Deno.env.get("PAYSTACK_SECRET_KEY")?.trim();
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

type PaystackApiResult = {
  ok: boolean;
  status: number;
  body: JsonMap | null;
};

async function paystackApiRequest(
  secretKey: string,
  path: string,
  method: "GET" | "POST" | "PUT",
  payload?: JsonMap,
): Promise<PaystackApiResult> {
  let response: Response;
  try {
    response = await fetch(`https://api.paystack.co${path}`, {
      method,
      headers: {
        Authorization: `Bearer ${secretKey}`,
        "Content-Type": "application/json",
      },
      ...(payload ? { body: JSON.stringify(payload) } : {}),
      signal: AbortSignal.timeout(15000),
    });
  } catch (error) {
    console.error("Paystack API request failed:", error);
    throw new Error("Paystack is temporarily unavailable.");
  }

  let body: unknown;
  try {
    body = await response.json();
  } catch (error) {
    console.error("Paystack response could not be read:", error);
    throw new Error("Paystack returned an unreadable response.");
  }
  if (!isRecord(body)) {
    console.error("Paystack response had an invalid shape.");
    throw new Error("Paystack returned an invalid response.");
  }
  return { ok: response.ok && body.status === true, status: response.status, body };
}

function getCustomerCode(value: unknown): string | null {
  if (!isRecord(value)) return null;
  const code = value.customer_code;
  return typeof code === "string" && /^CUS_[A-Za-z0-9]+$/.test(code)
    ? code
    : null;
}

function getDedicatedAccount(value: unknown): {
  accountNumber: string;
  bankName: string;
  accountName: string;
} | null {
  if (!isRecord(value)) return null;
  const accountNumber = value.account_number;
  const accountName = value.account_name;
  const bank = value.bank;
  const bankName = isRecord(bank) ? bank.name : value.bank_name;
  if (
    typeof accountNumber !== "string" ||
    !/^[0-9]{10,20}$/.test(accountNumber) ||
    typeof accountName !== "string" ||
    !accountName.trim() ||
    typeof bankName !== "string" ||
    !bankName.trim()
  ) {
    return null;
  }
  return {
    accountNumber,
    accountName: accountName.trim(),
    bankName: bankName.trim(),
  };
}

function normalizeNigerianPhone(value: string): string | null {
  const digits = value.replace(/\D/g, "");
  if (digits.startsWith("234") && digits.length === 13) return `+${digits}`;
  if (digits.startsWith("0") && digits.length === 11) return `+234${digits.slice(1)}`;
  if (digits.length === 10) return `+234${digits}`;
  return null;
}

async function findDedicatedAccount(
  secretKey: string,
  customerCode: string,
): Promise<ReturnType<typeof getDedicatedAccount>> {
  const query = new URLSearchParams({ customer: customerCode, currency: "NGN" });
  const result = await paystackApiRequest(
    secretKey,
    `/dedicated_account?${query.toString()}`,
    "GET",
  );
  if (!result.ok || !result.body || !Array.isArray(result.body.data)) {
    return null;
  }
  for (const account of result.body.data) {
    const details = getDedicatedAccount(account);
    if (details && isRecord(account) && account.active !== false) return details;
  }
  return null;
}

function matchesRequestedAmount(payment: JsonMap, expectedKobo: number): boolean {
  const amountKobo = Number(payment.amount);
  if (!Number.isSafeInteger(amountKobo) || amountKobo < expectedKobo) return false;

  const requestedAmount = payment.requested_amount;
  if (requestedAmount !== undefined && requestedAmount !== null) {
    const requestedKobo = Number(requestedAmount);
    if (Number.isSafeInteger(requestedKobo) && requestedKobo === expectedKobo) {
      return true;
    }
  }
  // Allow Paystack's automatic bank_transfer fee gross-up (up to 3% or NGN 250)
  const maxWithFeeKobo = expectedKobo + Math.max(25000, Math.round(expectedKobo * 0.03));
  return amountKobo >= expectedKobo && amountKobo <= maxWithFeeKobo;
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

async function clearUnpaidPendingFunding(
  admin: Awaited<ReturnType<typeof createPaystackClient>>,
  secretKey: string,
  userId: string,
): Promise<void> {
  const { data: pendingRows } = await admin
    .from("transactions")
    .select("reference, amount")
    .eq("user_id", userId)
    .eq("category", "wallet_fund")
    .eq("type", "credit")
    .eq("status", "pending")
    .order("created_at", { ascending: false })
    .limit(5);

  if (!Array.isArray(pendingRows) || pendingRows.length === 0) return;

  for (const row of pendingRows) {
    const ref = typeof row.reference === "string" ? row.reference : "";
    if (!ref) continue;
    try {
      const payment = await verifyPaystackTransaction(secretKey, ref);
      const expectedKobo = Math.round(Number(row.amount) * 100);
      if (
        payment.status === "success" &&
        payment.currency === "NGN" &&
        matchesRequestedAmount(payment, expectedKobo)
      ) {
        await admin.rpc("credit_paystack_wallet_funding", {
          p_user_id: userId,
          p_reference: ref,
          p_amount: row.amount,
        });
        continue;
      }
    } catch {
      // Not paid yet; close stale pending row so a fresh transfer can be created
    }
    await admin.rpc("fail_paystack_wallet_funding", {
      p_user_id: userId,
      p_reference: ref,
    });
  }
}

async function createBankTransferChargeAccount(
  admin: Awaited<ReturnType<typeof createPaystackClient>>,
  secretKey: string,
  userId: string,
  email: string,
  amountNaira: number,
): Promise<{
  accountNumber: string;
  bankName: string;
  accountName: string;
  reference: string;
  amountNaira: number;
  transferAmountNaira: number;
  expiresAt: string | null;
} | null> {
  await clearUnpaidPendingFunding(admin, secretKey, userId);

  const reference = `AVOFUND_${crypto.randomUUID().replaceAll("-", "")}`;
  const { error: prepareError } = await admin.rpc("prepare_paystack_wallet_funding", {
    p_user_id: userId,
    p_reference: reference,
    p_amount: amountNaira,
  });
  if (prepareError) {
    console.error("Could not prepare bank_transfer funding record:", prepareError.message);
    return null;
  }

  const expiresAtIso = new Date(Date.now() + 8 * 3600 * 1000).toISOString();
  const chargeRes = await paystackApiRequest(
    secretKey,
    "/charge",
    "POST",
    {
      email,
      amount: String(amountNaira * 100),
      reference,
      metadata: { user_id: userId, purpose: "wallet_funding" },
      bank_transfer: {
        account_expires_at: expiresAtIso,
      },
    },
  );

  if (!chargeRes.ok || !chargeRes.body || !isRecord(chargeRes.body.data)) {
    await admin.rpc("fail_paystack_wallet_funding", {
      p_user_id: userId,
      p_reference: reference,
    });
    return null;
  }

  const data = chargeRes.body.data;
  const account = getDedicatedAccount(data);
  if (!account) {
    await admin.rpc("fail_paystack_wallet_funding", {
      p_user_id: userId,
      p_reference: reference,
    });
    return null;
  }

  const rawChargeAmountKobo = Number(data.amount);
  const transferAmountNaira = Number.isFinite(rawChargeAmountKobo) && rawChargeAmountKobo > 0
    ? rawChargeAmountKobo / 100
    : amountNaira;

  return {
    accountNumber: account.accountNumber,
    bankName: account.bankName,
    accountName: account.accountName,
    reference,
    amountNaira,
    transferAmountNaira,
    expiresAt: typeof data.account_expires_at === "string"
      ? data.account_expires_at
      : expiresAtIso,
  };
}

async function handleWebhook(
  rawBody: string,
  suppliedSignature: string,
  config: NonNullable<ReturnType<typeof getServerConfig>>,
): Promise<Response> {
  if (!hasLivePaystackKey(config.paystackSecretKey)) {
    console.error("Paystack webhook blocked because the configured key is not Live.");
    return jsonResponse({ message: "Live wallet funding is not configured." }, 503);
  }

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
  if (!isRecord(event) || !isRecord(event.data)) {
    return jsonResponse({ received: true });
  }

  const admin = await createPaystackClient(config.supabaseUrl, config.serviceRoleKey);

  if (
    event.event === "dedicatedaccount.assign.success" ||
    event.event === "dedicatedaccount.assign.failed"
  ) {
    const customerCode = getCustomerCode(event.data.customer);
    if (!customerCode) return jsonResponse({ received: true });

    const { data: wallet, error: walletError } = await admin
      .from("wallets")
      .select("user_id")
      .eq("paystack_customer_code", customerCode)
      .maybeSingle();
    if (walletError || !wallet) {
      return jsonResponse({ received: true });
    }

    if (event.event === "dedicatedaccount.assign.failed") {
      await admin.rpc("fail_paystack_dedicated_wallet_account", {
        p_user_id: wallet.user_id,
      });
      return jsonResponse({ received: true });
    }

    try {
      const assignedAccount = await findDedicatedAccount(
        config.paystackSecretKey,
        customerCode,
      );
      if (assignedAccount) {
        await admin.rpc("save_paystack_dedicated_wallet_account", {
          p_user_id: wallet.user_id,
          p_customer_code: customerCode,
          p_account_number: assignedAccount.accountNumber,
          p_bank_name: assignedAccount.bankName,
          p_account_name: assignedAccount.accountName,
        });
      }
    } catch (error) {
      console.error("Paystack webhook dedicated account verification failed:", error);
      return jsonResponse({ message: "Account verification temporarily unavailable." }, 503);
    }
    return jsonResponse({ received: true });
  }

  if (event.event !== "charge.success") return jsonResponse({ received: true });

  const reference = String(event.data.reference ?? "");
  if (!/^[A-Za-z0-9_-]{10,100}$/.test(reference)) {
    return jsonResponse({ message: "Invalid payment reference." }, 400);
  }

  const { data: transaction, error: transactionError } = await admin
    .from("transactions")
    .select("user_id, amount, status, category, type")
    .eq("reference", reference)
    .maybeSingle();
  if (transactionError) {
    console.error("Paystack webhook transaction lookup failed.");
    return jsonResponse({ message: "Payment record lookup failed." }, 503);
  }
  if (!transaction) {
    let payment: JsonMap;
    try {
      payment = await verifyPaystackTransaction(config.paystackSecretKey, reference);
    } catch (error) {
      console.error("Paystack dedicated transfer verification failed:", error);
      return jsonResponse({ message: "Payment verification is temporarily unavailable." }, 503);
    }

    const customerCode = getCustomerCode(payment.customer);
    const amountKobo = Number(payment.amount);
    const eventCustomerCode = getCustomerCode(event.data.customer);
    if (
      payment.reference !== reference ||
      payment.status !== "success" ||
      payment.currency !== "NGN" ||
      !Number.isSafeInteger(amountKobo) ||
      amountKobo <= 0 ||
      !["bank_transfer", "dedicated_nuban", "bank"].includes(String(payment.channel)) ||
      !customerCode ||
      (eventCustomerCode && eventCustomerCode !== customerCode)
    ) {
      console.error("Paystack transfer details did not match a valid dedicated account deposit.");
      return jsonResponse({ received: true });
    }

    const { data: wallet, error: walletError } = await admin
      .from("wallets")
      .select("user_id")
      .eq("paystack_customer_code", customerCode)
      .eq("paystack_dva_status", "assigned")
      .not("virtual_account_number", "is", null)
      .maybeSingle();
    if (walletError) {
      console.error("Paystack dedicated transfer account lookup failed.");
      return jsonResponse({ message: "Transfer account lookup failed." }, 503);
    }
    if (!wallet) return jsonResponse({ received: true });

    const requestedKobo = Number(payment.requested_amount);
    const creditKobo = Number.isSafeInteger(requestedKobo) && requestedKobo > 0
      ? Math.min(amountKobo, requestedKobo)
      : amountKobo;
    const amountNaira = Math.floor(creditKobo / 100);
    if (amountNaira <= 0) return jsonResponse({ received: true });

    const { error: creditError } = await admin.rpc(
      "credit_paystack_dedicated_wallet_funding",
      {
        p_user_id: wallet.user_id,
        p_customer_code: customerCode,
        p_reference: reference,
        p_amount: amountNaira,
      },
    );
    if (creditError) {
      console.error("Paystack dedicated transfer wallet credit failed:", creditError.message);
      return jsonResponse({ message: "Wallet credit is temporarily unavailable." }, 503);
    }
    return jsonResponse({ received: true });
  }
  if (transaction.category !== "wallet_fund" || transaction.type !== "credit") {
    console.error("Paystack webhook reference belongs to a different transaction type.");
    return jsonResponse({ received: true });
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
    !matchesRequestedAmount(payment, expectedKobo)
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
  if (!hasLivePaystackKey(config.paystackSecretKey)) {
    console.error("Paystack initialization blocked because the configured key is not Live.");
    return jsonResponse({ message: "Live wallet funding is not configured." }, 503);
  }

  const amount = Number(body.amount);
  if (!Number.isInteger(amount) || amount < 100 || amount > 1000000) {
    return jsonResponse({ message: "Enter an amount between ₦100 and ₦1,000,000." }, 400);
  }

  const rawCallbackUrl = Deno.env.get("PAYSTACK_CALLBACK_URL")?.trim() ||
    "https://adevictorolu.github.io/Avotek/";
  let callback: URL;
  try {
    callback = new URL(rawCallbackUrl);
    if (
      callback.protocol !== "https:" ||
      callback.hostname !== "adevictorolu.github.io"
    ) {
      callback = new URL("https://adevictorolu.github.io/Avotek/");
    }
  } catch {
    callback = new URL("https://adevictorolu.github.io/Avotek/");
  }

  // Clear any unpaid stale pending wallet_fund row so the user is never blocked by 409
  await clearUnpaidPendingFunding(admin, config.paystackSecretKey, user.id);

  const reference = `AVOFUND_${crypto.randomUUID().replaceAll("-", "")}`;
  const { data: prepared, error: prepareError } = await admin.rpc("prepare_paystack_wallet_funding", {
    p_user_id: user.id,
    p_reference: reference,
    p_amount: amount,
  });
  if (prepareError) {
    console.error("Could not create pending wallet funding record:", prepareError.message);
    return jsonResponse({ message: "Could not start wallet funding. Please try again." }, 503);
  }
  if (isRecord(prepared) && prepared.already_pending === true) {
    return jsonResponse({
      message: "A wallet funding payment is already pending. Check its status before starting another.",
      reference: prepared.reference,
    }, 409);
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
        channels: ["bank_transfer", "card", "ussd", "bank"],
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

async function handleDedicatedAccount(
  admin: Awaited<ReturnType<typeof createPaystackClient>>,
  config: NonNullable<ReturnType<typeof getServerConfig>>,
  user: { id: string; email: string },
  body: JsonMap,
): Promise<Response> {
  if (!hasLivePaystackKey(config.paystackSecretKey)) {
    console.error("Dedicated account assignment blocked because the configured key is not Live.");
    return jsonResponse({ message: "Live wallet funding is not configured." }, 503);
  }

  const { data: profile } = await admin
    .from("profiles")
    .select("email, full_name, phone")
    .eq("id", user.id)
    .maybeSingle();

  const suppliedFullName = typeof body.full_name === "string"
    ? body.full_name.trim()
    : "";
  const suppliedPhone = typeof body.phone === "string"
    ? body.phone.trim()
    : "";
  const requestedAmountRaw = Number(body.amount);
  const requestedAmountNaira =
    Number.isInteger(requestedAmountRaw) &&
      requestedAmountRaw >= 100 &&
      requestedAmountRaw <= 1000000
      ? requestedAmountRaw
      : 1000;
  const forceNewTransfer = body.force_new === true ||
    (Number.isInteger(requestedAmountRaw) && requestedAmountRaw >= 100);

  const effectiveFullName = suppliedFullName ||
    String(profile?.full_name ?? "").trim() ||
    user.email.split("@")[0];
  const effectivePhoneRaw = suppliedPhone ||
    String(profile?.phone ?? "").trim();

  const nameParts = effectiveFullName.split(/\s+/).filter(Boolean);
  const firstName = nameParts[0] || "Avotek";
  const lastName = nameParts.length > 1 ? nameParts.slice(1).join(" ") : "Customer";
  const phone = normalizeNigerianPhone(effectivePhoneRaw) ?? "+2348000000000";

  if (
    profile &&
    ((suppliedFullName && suppliedFullName !== String(profile.full_name ?? "").trim()) ||
      (suppliedPhone && normalizeNigerianPhone(suppliedPhone) !== null))
  ) {
    await admin
      .from("profiles")
      .update({
        ...(suppliedFullName ? { full_name: effectiveFullName } : {}),
        ...(suppliedPhone ? { phone: suppliedPhone } : {}),
        updated_at: new Date().toISOString(),
      })
      .eq("id", user.id);
  }

  const { data: claim, error: claimError } = await admin.rpc(
    "claim_paystack_dedicated_wallet_account",
    { p_user_id: user.id },
  );
  if (claimError || !isRecord(claim)) {
    console.error("Could not claim Paystack dedicated account assignment:", claimError?.message);
    return jsonResponse({ message: "Could not prepare your personal transfer account. Please try again." }, 503);
  }

  const claimStatus = claim.status;
  if (claimStatus === "assigned" && !forceNewTransfer) {
    const account = getDedicatedAccount({
      account_number: claim.account_number,
      account_name: claim.account_name,
      bank_name: claim.bank_name,
    });
    if (account) {
      // Look up latest pending wallet_fund reference if any
      const { data: latestPending } = await admin
        .from("transactions")
        .select("reference, amount")
        .eq("user_id", user.id)
        .eq("category", "wallet_fund")
        .eq("type", "credit")
        .eq("status", "pending")
        .order("created_at", { ascending: false })
        .limit(1)
        .maybeSingle();

      return jsonResponse({
        status: "assigned",
        account_number: account.accountNumber,
        bank_name: account.bankName,
        account_name: account.accountName,
        reference: latestPending?.reference ?? null,
        amount_naira: latestPending ? Number(latestPending.amount) : null,
      });
    }
  }

  const email = String(profile?.email ?? user.email).trim().toLowerCase();
  let customerCode = getCustomerCode({ customer_code: claim.customer_code });
  if (!customerCode) {
    const existingCustomer = await paystackApiRequest(
      config.paystackSecretKey,
      `/customer/${encodeURIComponent(email)}`,
      "GET",
    );
    if (existingCustomer.ok && existingCustomer.body) {
      customerCode = getCustomerCode(existingCustomer.body.data);
      if (customerCode) {
        await paystackApiRequest(
          config.paystackSecretKey,
          `/customer/${encodeURIComponent(customerCode)}`,
          "PUT",
          {
            first_name: firstName,
            last_name: lastName,
            phone,
            metadata: { avotek_user_id: user.id },
          },
        );
      }
    } else if (existingCustomer.status === 404) {
      const createdCustomer = await paystackApiRequest(
        config.paystackSecretKey,
        "/customer",
        "POST",
        {
          email,
          first_name: firstName,
          last_name: lastName,
          phone,
          metadata: { avotek_user_id: user.id },
        },
      );
      if (createdCustomer.ok && createdCustomer.body) {
        customerCode = getCustomerCode(createdCustomer.body.data);
      }
    }
  }

  if (customerCode) {
    await admin.rpc("save_paystack_customer_code", {
      p_user_id: user.id,
      p_customer_code: customerCode,
    });
  }

  let assignedAccount: ReturnType<typeof getDedicatedAccount> = null;
  if (customerCode && !forceNewTransfer) {
    try {
      assignedAccount = await findDedicatedAccount(config.paystackSecretKey, customerCode);
    } catch {
      assignedAccount = null;
    }

    if (!assignedAccount) {
      const assignment = await paystackApiRequest(
        config.paystackSecretKey,
        "/dedicated_account",
        "POST",
        { customer: customerCode },
      );
      if (assignment.ok && assignment.body) {
        assignedAccount = getDedicatedAccount(assignment.body.data);
      }
    }
  }

  let transferRef: string | null = null;
  let transferAmountNaira: number | null = null;
  let expiresAt: string | null = null;

  // Fallback to Paystack Live Charge bank_transfer (Paystack-Titan) when Dedicated NUBAN is unavailable or when generating an amount-specific transfer account
  if (!assignedAccount) {
    const chargeAccount = await createBankTransferChargeAccount(
      admin,
      config.paystackSecretKey,
      user.id,
      email,
      requestedAmountNaira,
    );
    if (!chargeAccount) {
      await admin.rpc("fail_paystack_dedicated_wallet_account", {
        p_user_id: user.id,
      });
      return jsonResponse({
        message: "Paystack could not generate a bank transfer account right now. Please try again.",
      }, 502);
    }
    assignedAccount = {
      accountNumber: chargeAccount.accountNumber,
      bankName: chargeAccount.bankName,
      accountName: chargeAccount.accountName,
    };
    transferRef = chargeAccount.reference;
    transferAmountNaira = chargeAccount.transferAmountNaira;
    expiresAt = chargeAccount.expiresAt;
  }

  if (customerCode) {
    await admin.rpc(
      "save_paystack_dedicated_wallet_account",
      {
        p_user_id: user.id,
        p_customer_code: customerCode,
        p_account_number: assignedAccount.accountNumber,
        p_bank_name: assignedAccount.bankName,
        p_account_name: assignedAccount.accountName,
      },
    );
  } else {
    await admin
      .from("wallets")
      .update({
        virtual_account_number: assignedAccount.accountNumber,
        virtual_account_bank: assignedAccount.bankName,
        virtual_account_name: assignedAccount.accountName,
        paystack_dva_status: "assigned",
        paystack_dva_requested_at: null,
        updated_at: new Date().toISOString(),
      })
      .eq("user_id", user.id);
  }

  return jsonResponse({
    status: "assigned",
    account_number: assignedAccount.accountNumber,
    bank_name: assignedAccount.bankName,
    account_name: assignedAccount.accountName,
    reference: transferRef,
    amount_naira: requestedAmountNaira,
    transfer_amount_naira: transferAmountNaira,
    expires_at: expiresAt,
  });
}

async function handleVerify(
  admin: Awaited<ReturnType<typeof createPaystackClient>>,
  config: NonNullable<ReturnType<typeof getServerConfig>>,
  user: { id: string; email: string },
  body: JsonMap,
): Promise<Response> {
  let reference = String(body.reference ?? "").trim();

  // If no reference was passed, verify the user's most recent pending wallet_fund transaction
  if (!reference) {
    const { data: latestPending } = await admin
      .from("transactions")
      .select("reference")
      .eq("user_id", user.id)
      .eq("category", "wallet_fund")
      .eq("type", "credit")
      .eq("status", "pending")
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (!latestPending?.reference) {
      return jsonResponse({ status: "none", credited: false });
    }
    reference = String(latestPending.reference);
  }

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
    return jsonResponse({
      status: "completed",
      credited: false,
      reference,
      amount: Number(transaction.amount),
      currency: "NGN",
    });
  }
  if (!["pending", "failed"].includes(transaction.status)) {
    return jsonResponse({ status: transaction.status, credited: false });
  }
  if (!hasLivePaystackKey(config.paystackSecretKey)) {
    console.error("Paystack verification blocked because the configured key is not Live.");
    return jsonResponse({ message: "Live wallet funding is not configured." }, 503);
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
    !matchesRequestedAmount(payment, expectedKobo)
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
    return jsonResponse({
      status: "pending",
      credited: false,
      reference,
      amount: Number(transaction.amount),
      currency: "NGN",
    });
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
  return jsonResponse({
    status: "completed",
    credited: true,
    reference,
    amount: Number(transaction.amount),
    currency: "NGN",
  });
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
  if (body.action === "dedicated_account") {
    return await handleDedicatedAccount(admin, config, user, body);
  }
  if (body.action === "verify" || body.action === "verify_latest") {
    return await handleVerify(admin, config, user, body);
  }
  return jsonResponse({ message: "Unsupported payment operation." }, 400);
});
