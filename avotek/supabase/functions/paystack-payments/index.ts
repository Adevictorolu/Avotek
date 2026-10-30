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

function hasValidPaystackKey(secretKey: string): boolean {
  const trimmed = secretKey.trim();
  return trimmed.startsWith("sk_live_") || trimmed.startsWith("sk_test_");
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
  const rawNum = value.account_number ??
    (isRecord(value.bank) ? value.bank.account_number : null) ??
    (isRecord(value.assignment) ? value.assignment.account_number : null);
  const accountNumber = rawNum != null ? String(rawNum).trim() : "";

  const bank = value.bank;
  let bankName = typeof bank === "string"
    ? bank
    : isRecord(bank) && typeof bank.name === "string"
    ? bank.name
    : typeof value.bank_name === "string"
    ? value.bank_name
    : "";

  let accountName = typeof value.account_name === "string" ? value.account_name.trim() : "";

  // Normalize Paystack Titan Trust Bank naming for seamless recognition in Nigerian banking apps
  if (
    bankName === "Paystack-Titan" ||
    bankName.toLowerCase() === "titan paystack" ||
    bankName.toLowerCase().includes("titan")
  ) {
    bankName = "Titan Trust Bank (Paystack)";
  }

  if (
    !accountNumber ||
    !/^[0-9]{10,20}$/.test(accountNumber)
  ) {
    return null;
  }

  if (!bankName) bankName = "Titan Trust Bank (Paystack)";
  if (!accountName) accountName = "Avotek Customer / Paystack Checkout";

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

function formatPersonalizedAccountName(
  fullName: string | null | undefined,
  email: string,
  providerAccountName: string,
): string {
  const rawName = (fullName ?? "").trim();
  const cleanName = rawName && rawName.toLowerCase() !== "avotek user"
    ? rawName
    : email.split("@")[0].replace(/[._-]+/g, " ").trim() || "Avotek User";
  const upperUser = cleanName.toUpperCase();
  const upperProvider = providerAccountName.trim().toUpperCase();
  if (upperProvider.includes(upperUser)) {
    return upperProvider;
  }
  if (upperProvider === "PAYSTACK CHECKOUT" || upperProvider.includes("PAYSTACK")) {
    return `${upperUser} / PAYSTACK CHECKOUT`;
  }
  return `${upperUser} / ${upperProvider}`;
}

/**
 * Calculates the net wallet credit after deducting Paystack's transaction fee.
 * Example: If a user pays ₦100.00 (10,000 kobo), Paystack's 1.5% fee (₦1.50 = 150 kobo)
 * is subtracted, crediting ₦98.50 to the user's Avotek wallet.
 */
function calculateNetFunding(payment: JsonMap): {
  grossNaira: number;
  feeNaira: number;
  netNaira: number;
  narration: string;
} {
  const rawAmountKobo = Number(payment.amount);
  const grossKobo = Number.isFinite(rawAmountKobo) && rawAmountKobo > 0
    ? Math.round(rawAmountKobo)
    : 0;
  const reportedFeeKobo = Number.isFinite(Number(payment.fees)) && Number(payment.fees) > 0
    ? Math.round(Number(payment.fees))
    : 0;
  // Standard Paystack local fee: 1.5% (plus ₦100 for payments >= ₦2,500, capped at ₦2,000)
  const flatFeeKobo = grossKobo >= 250000 ? 10000 : 0;
  const standardFeeKobo = Math.min(200000, Math.round(grossKobo * 0.015) + flatFeeKobo);
  const feeKobo = Math.max(reportedFeeKobo, standardFeeKobo);
  const netKobo = Math.max(0, grossKobo - feeKobo);

  const grossNaira = Math.round(grossKobo) / 100;
  const feeNaira = Math.round(feeKobo) / 100;
  const netNaira = Math.round(netKobo) / 100;
  const narration =
    `Paystack wallet funding (₦${grossNaira.toFixed(2)} paid - ₦${feeNaira.toFixed(2)} Paystack fee = ₦${netNaira.toFixed(2)} credited)`;

  return { grossNaira, feeNaira, netNaira, narration };
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
      const amountKobo = Number(payment.amount);
      if (
        payment.status === "success" &&
        payment.currency === "NGN" &&
        Number.isSafeInteger(amountKobo) &&
        amountKobo > 0
      ) {
        const net = calculateNetFunding(payment);
        if (net.netNaira > 0) {
          await admin.rpc("credit_paystack_wallet_funding", {
            p_user_id: userId,
            p_reference: ref,
            p_amount: net.netNaira,
            p_narration: net.narration,
          });
          continue;
        }
      }
      // If payment is not successful, remove the stale pending row so phantom transactions don't pollute the ledger
      await admin.from("transactions").delete().eq("user_id", userId).eq("reference", ref).eq("status", "pending");
    } catch {
      // Not paid; delete stale pending row so phantom transactions don't pollute the user ledger
      await admin.from("transactions").delete().eq("user_id", userId).eq("reference", ref).eq("status", "pending");
    }
  }
}

async function createBankTransferChargeAccount(
  admin: Awaited<ReturnType<typeof createPaystackClient>>,
  secretKey: string,
  userId: string,
  email: string,
  amountNaira: number,
  fullName?: string | null,
): Promise<{
  accountNumber: string;
  bankName: string;
  accountName: string;
  reference: string;
  amountNaira: number;
  transferAmountNaira: number;
  netCreditNaira: number;
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
      metadata: {
        user_id: userId,
        purpose: "wallet_funding",
        full_name: fullName ?? email,
      },
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

  const personalizedName = formatPersonalizedAccountName(
    fullName,
    email,
    account.accountName,
  );
  const netPreview = calculateNetFunding({ amount: amountNaira * 100, fees: 0 });

  return {
    accountNumber: account.accountNumber,
    bankName: account.bankName,
    accountName: personalizedName,
    reference,
    amountNaira,
    transferAmountNaira: amountNaira,
    netCreditNaira: netPreview.netNaira,
    expiresAt: typeof data.account_expires_at === "string"
      ? data.account_expires_at
      : expiresAtIso,
  };
}

async function ensureCustomerCodeForUser(
  admin: Awaited<ReturnType<typeof createPaystackClient>>,
  secretKey: string,
  userId: string,
  email: string,
  fullName: string,
  phoneRaw: string,
  existingCode?: string | null,
): Promise<string | null> {
  const cleanEmail = email.trim().toLowerCase();
  const cleanName = fullName.trim() && fullName.trim().toLowerCase() !== "avotek user"
    ? fullName.trim()
    : cleanEmail.split("@")[0].replace(/[._-]+/g, " ").trim() || "Avotek Customer";
  const parts = cleanName.split(/\s+/).filter(Boolean);
  const firstName = parts[0] || "Avotek";
  const lastName = parts.length > 1 ? parts.slice(1).join(" ") : "Customer";
  const phone = normalizeNigerianPhone(phoneRaw) ?? "+2348000000000";

  let customerCode = existingCode && /^CUS_[A-Za-z0-9]+$/.test(existingCode)
    ? existingCode
    : null;

  if (!customerCode) {
    const existingCustomer = await paystackApiRequest(
      secretKey,
      `/customer/${encodeURIComponent(cleanEmail)}`,
      "GET",
    );
    if (existingCustomer.ok && existingCustomer.body) {
      customerCode = getCustomerCode(existingCustomer.body.data);
    } else if (existingCustomer.status === 404) {
      const created = await paystackApiRequest(secretKey, "/customer", "POST", {
        email: cleanEmail,
        first_name: firstName,
        last_name: lastName,
        phone,
        metadata: { avotek_user_id: userId },
      });
      if (created.ok && created.body) {
        customerCode = getCustomerCode(created.body.data);
      }
    }
  }

  if (customerCode) {
    await paystackApiRequest(
      secretKey,
      `/customer/${encodeURIComponent(customerCode)}`,
      "PUT",
      {
        first_name: firstName,
        last_name: lastName,
        phone,
        metadata: { avotek_user_id: userId },
      },
    ).catch(() => null);

    await admin.rpc("save_paystack_customer_code", {
      p_user_id: userId,
      p_customer_code: customerCode,
    });
  }

  return customerCode;
}

async function rotateDefaultTransferAccountIfNeeded(
  admin: Awaited<ReturnType<typeof createPaystackClient>>,
  secretKey: string,
  userId: string,
): Promise<void> {
  try {
    const { data: wallet } = await admin
      .from("wallets")
      .select("virtual_account_bank, paystack_customer_code")
      .eq("user_id", userId)
      .maybeSingle();
    if (!wallet || wallet.virtual_account_bank !== "Paystack-Titan") return;

    const { data: profile } = await admin
      .from("profiles")
      .select("email, full_name")
      .eq("id", userId)
      .maybeSingle();
    if (!profile?.email) return;

    const fresh = await createBankTransferChargeAccount(
      admin,
      secretKey,
      userId,
      String(profile.email).trim().toLowerCase(),
      100,
      String(profile.full_name ?? ""),
    );
    if (fresh) {
      await admin.rpc("save_paystack_dedicated_wallet_account", {
        p_user_id: userId,
        p_customer_code: String(wallet.paystack_customer_code ?? ""),
        p_account_number: fresh.accountNumber,
        p_bank_name: fresh.bankName,
        p_account_name: fresh.accountName,
      });
    }
  } catch (err) {
    console.error("Could not auto-rotate Paystack-Titan account:", err);
  }
}

async function handleWebhook(
  rawBody: string,
  suppliedSignature: string,
  config: NonNullable<ReturnType<typeof getServerConfig>>,
): Promise<Response> {
  if (!hasValidPaystackKey(config.paystackSecretKey)) {
    console.error("Paystack webhook blocked because the configured key is not valid.");
    return jsonResponse({ message: "Paystack wallet funding is not configured." }, 503);
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
  if (!/^[A-Za-z0-9_-]{8,100}$/.test(reference)) {
    return jsonResponse({ message: "Invalid payment reference." }, 400);
  }

  let payment: JsonMap;
  try {
    payment = await verifyPaystackTransaction(config.paystackSecretKey, reference);
  } catch (error) {
    console.error("Paystack webhook verification request failed:", error);
    return jsonResponse({ message: "Payment verification is temporarily unavailable." }, 503);
  }

  const amountKobo = Number(payment.amount);
  if (
    payment.reference !== reference ||
    payment.status !== "success" ||
    payment.currency !== "NGN" ||
    !Number.isSafeInteger(amountKobo) ||
    amountKobo <= 0
  ) {
    return jsonResponse({ received: true });
  }

  const net = calculateNetFunding(payment);
  if (net.netNaira <= 0) {
    return jsonResponse({ received: true });
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

  if (transaction) {
    if (transaction.category !== "wallet_fund" || transaction.type !== "credit") {
      return jsonResponse({ received: true });
    }
    if (transaction.status === "completed") return jsonResponse({ received: true });
    if (!["pending", "failed"].includes(transaction.status)) {
      return jsonResponse({ received: true });
    }

    const { error: creditError } = await admin.rpc("credit_paystack_wallet_funding", {
      p_user_id: transaction.user_id,
      p_reference: reference,
      p_amount: net.netNaira,
      p_narration: net.narration,
    });
    if (creditError) {
      console.error("Paystack webhook wallet credit failed:", creditError.message);
      return jsonResponse({ message: "Wallet credit is temporarily unavailable." }, 503);
    }

    if (String(payment.channel) === "bank_transfer") {
      await rotateDefaultTransferAccountIfNeeded(
        admin,
        config.paystackSecretKey,
        transaction.user_id,
      );
    }
    return jsonResponse({ received: true });
  }

  // No matching local reference: match by metadata.user_id, customer_code, or customer.email
  const customerCode = getCustomerCode(payment.customer);
  const metadataUserId = isRecord(payment.metadata) && typeof payment.metadata.user_id === "string"
    ? payment.metadata.user_id
    : null;
  const customerEmail = isRecord(payment.customer) && typeof payment.customer.email === "string"
    ? payment.customer.email.trim().toLowerCase()
    : null;

  let targetUserId: string | null = metadataUserId;
  if (!targetUserId && customerCode) {
    const { data: walletByCode } = await admin
      .from("wallets")
      .select("user_id")
      .eq("paystack_customer_code", customerCode)
      .maybeSingle();
    if (walletByCode?.user_id) targetUserId = String(walletByCode.user_id);
  }
  if (!targetUserId && customerEmail) {
    const { data: profileByEmail } = await admin
      .from("profiles")
      .select("id")
      .ilike("email", customerEmail)
      .maybeSingle();
    if (profileByEmail?.id) targetUserId = String(profileByEmail.id);
  }

  if (!targetUserId) {
    return jsonResponse({ received: true });
  }

  const { error: creditError } = await admin.rpc(
    "credit_paystack_dedicated_wallet_funding",
    {
      p_user_id: targetUserId,
      p_customer_code: customerCode ?? "",
      p_reference: reference,
      p_amount: net.netNaira,
      p_narration: net.narration,
    },
  );
  if (creditError) {
    console.error("Paystack dedicated transfer wallet credit failed:", creditError.message);
    return jsonResponse({ message: "Wallet credit is temporarily unavailable." }, 503);
  }

  if (String(payment.channel) === "bank_transfer") {
    await rotateDefaultTransferAccountIfNeeded(
      admin,
      config.paystackSecretKey,
      targetUserId,
    );
  }
  return jsonResponse({ received: true });
}

async function authenticateUser(
  request: Request,
  supabaseUrl: string,
): Promise<{ id: string; email: string }> | Promise<null> {
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
  if (!hasValidPaystackKey(config.paystackSecretKey)) {
    console.error("Paystack initialization blocked because the configured key is not valid.");
    return jsonResponse({ message: "Paystack wallet funding is not configured." }, 503);
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
  if (!hasValidPaystackKey(config.paystackSecretKey)) {
    console.error("Dedicated account assignment blocked because the configured key is not valid.");
    return jsonResponse({ message: "Paystack wallet funding is not configured." }, 503);
  }

  const { data: profile } = await admin
    .from("profiles")
    .select("email, full_name, phone")
    .eq("id", user.id)
    .maybeSingle();

  const suppliedFullName = typeof body.full_name === "string" ? body.full_name.trim() : "";
  const suppliedPhone = typeof body.phone === "string" ? body.phone.trim() : "";
  const effectiveFullName = suppliedFullName || String(profile?.full_name ?? "").trim();
  const effectivePhoneRaw = suppliedPhone || String(profile?.phone ?? "").trim();
  const email = String(profile?.email ?? user.email).trim().toLowerCase();

  if (
    profile &&
    ((suppliedFullName && suppliedFullName !== String(profile.full_name ?? "").trim()) ||
      (suppliedPhone && suppliedPhone !== String(profile.phone ?? "").trim()))
  ) {
    await admin
      .from("profiles")
      .update({
        ...(suppliedFullName ? { full_name: suppliedFullName } : {}),
        ...(suppliedPhone ? { phone: suppliedPhone } : {}),
        updated_at: new Date().toISOString(),
      })
      .eq("id", user.id);
  }

  const { data: existingWallet } = await admin
    .from("wallets")
    .select(
      "virtual_account_number, virtual_account_bank, virtual_account_name, paystack_customer_code, paystack_dva_status, paystack_dva_requested_at",
    )
    .eq("user_id", user.id)
    .maybeSingle();

  const forceNew = body.force_new === true;

  // 1. If the wallet already has a permanent non-Paystack-Titan account, return it immediately.
  if (
    existingWallet?.paystack_dva_status === "assigned" &&
    existingWallet.virtual_account_number &&
    existingWallet.virtual_account_bank &&
    existingWallet.virtual_account_bank !== "Paystack-Titan"
  ) {
    return jsonResponse({
      status: "assigned",
      account_number: existingWallet.virtual_account_number,
      bank_name: existingWallet.virtual_account_bank,
      account_name: existingWallet.virtual_account_name,
    });
  }

  // 2. If the wallet has an active Paystack-Titan account assigned within the last 6 hours, reuse it
  if (
    !forceNew &&
    existingWallet?.paystack_dva_status === "assigned" &&
    existingWallet.virtual_account_number &&
    existingWallet.virtual_account_bank === "Paystack-Titan"
  ) {
    const requestedAtMs = existingWallet.paystack_dva_requested_at
      ? Date.parse(String(existingWallet.paystack_dva_requested_at))
      : 0;
    const isFresh = Number.isFinite(requestedAtMs) &&
      requestedAtMs > 0 &&
      (Date.now() - requestedAtMs) < 6 * 3600 * 1000;

    if (isFresh) {
      const expectedName = formatPersonalizedAccountName(
        effectiveFullName,
        email,
        existingWallet.virtual_account_name ?? "PAYSTACK CHECKOUT",
      );
      if (existingWallet.virtual_account_name !== expectedName) {
        await admin.rpc("save_paystack_dedicated_wallet_account", {
          p_user_id: user.id,
          p_customer_code: String(existingWallet.paystack_customer_code ?? ""),
          p_account_number: existingWallet.virtual_account_number,
          p_bank_name: existingWallet.virtual_account_bank,
          p_account_name: expectedName,
        });
      }
      return jsonResponse({
        status: "assigned",
        account_number: existingWallet.virtual_account_number,
        bank_name: existingWallet.virtual_account_bank,
        account_name: expectedName,
      });
    }
  }

  // 3. Ensure Paystack customer code exists and is linked to this wallet
  const customerCode = await ensureCustomerCodeForUser(
    admin,
    config.paystackSecretKey,
    user.id,
    email,
    effectiveFullName,
    effectivePhoneRaw,
    existingWallet?.paystack_customer_code
      ? String(existingWallet.paystack_customer_code)
      : null,
  );

  // 4. Try Paystack Dedicated NUBAN first if enabled on the merchant account
  const providers = await paystackApiRequest(
    config.paystackSecretKey,
    "/dedicated_account/available_providers",
    "GET",
  );
  console.log("Paystack /dedicated_account/available_providers:", JSON.stringify(providers));

  const cleanName = effectiveFullName && effectiveFullName.toLowerCase() !== "avotek user"
    ? effectiveFullName
    : email.split("@")[0].replace(/[._-]+/g, " ").trim() || "Avotek Customer";
  const parts = cleanName.split(/\s+/).filter(Boolean);
  const firstName = parts[0] || "Avotek";
  const lastName = parts.length > 1 ? parts.slice(1).join(" ") : "Customer";
  const phone = normalizeNigerianPhone(effectivePhoneRaw) ?? "+2348000000000";

  let assignedAccount: ReturnType<typeof getDedicatedAccount> = null;

  if (providers.ok) {
    const providerList = Array.isArray(providers.body?.data) ? providers.body.data : [];
    const wema = providerList.find((item) => isRecord(item) && item.provider_slug === "wema-bank");
    const firstProvider = providerList.find((item) =>
      isRecord(item) && typeof item.provider_slug === "string"
    );
    const preferredBank = isRecord(wema)
      ? String(wema.provider_slug)
      : isRecord(firstProvider)
      ? String(firstProvider.provider_slug)
      : "wema-bank";

    // A. Single-step Dedicated Account Assignment
    const directAssign = await paystackApiRequest(
      config.paystackSecretKey,
      "/dedicated_account/assign",
      "POST",
      {
        email,
        first_name: firstName,
        last_name: lastName,
        phone,
        preferred_bank: preferredBank,
        country: "NG",
      },
    );
    console.log("Paystack /dedicated_account/assign response:", JSON.stringify(directAssign));
    if (directAssign.ok && directAssign.body) {
      assignedAccount = getDedicatedAccount(directAssign.body.data ?? directAssign.body);
    }

    // B. If not assigned, try via customer code
    if (!assignedAccount && customerCode) {
      assignedAccount = await findDedicatedAccount(config.paystackSecretKey, customerCode).catch(
        () => null,
      );
      if (!assignedAccount) {
        const assignment = await paystackApiRequest(
          config.paystackSecretKey,
          "/dedicated_account",
          "POST",
          {
            customer: customerCode,
            preferred_bank: preferredBank,
          },
        );
        console.log("Paystack /dedicated_account POST response:", JSON.stringify(assignment));
        if (assignment.ok && assignment.body) {
          assignedAccount = getDedicatedAccount(assignment.body.data);
        }
      }
    }
  }

  if (assignedAccount) {
    await admin.rpc("save_paystack_dedicated_wallet_account", {
      p_user_id: user.id,
      p_customer_code: customerCode ?? "",
      p_account_number: assignedAccount.accountNumber,
      p_bank_name: assignedAccount.bankName,
      p_account_name: assignedAccount.accountName,
    });
    return jsonResponse({
      status: "assigned",
      account_number: assignedAccount.accountNumber,
      bank_name: assignedAccount.bankName,
      account_name: assignedAccount.accountName,
    });
  }

  // 5. Automatic Default Paystack-Titan Bank Transfer Account Strategy:
  // Generate a live Paystack-Titan transfer account automatically and attach it to the user's wallet
  // with "<USER NAME> / PAYSTACK CHECKOUT" so the user always has an active default account number on screen.
  const requestedAmount = Number(body.amount);
  const baseAmountNaira =
    Number.isInteger(requestedAmount) && requestedAmount >= 100 && requestedAmount <= 1000000
      ? requestedAmount
      : 100;

  const fallbackTransfer = await createBankTransferChargeAccount(
    admin,
    config.paystackSecretKey,
    user.id,
    email,
    baseAmountNaira,
    effectiveFullName,
  );
  if (!fallbackTransfer) {
    return jsonResponse({
      message: "Paystack could not prepare your transfer account right now. Please try again.",
      providers_debug: providers,
    }, 502);
  }

  const { error: saveError } = await admin.rpc("save_paystack_dedicated_wallet_account", {
    p_user_id: user.id,
    p_customer_code: customerCode ?? "",
    p_account_number: fallbackTransfer.accountNumber,
    p_bank_name: fallbackTransfer.bankName,
    p_account_name: fallbackTransfer.accountName,
  });
  if (saveError) {
    console.error("Could not save automatic Paystack-Titan account:", saveError.message);
  }

  return jsonResponse({
    status: "assigned",
    account_number: fallbackTransfer.accountNumber,
    bank_name: fallbackTransfer.bankName,
    account_name: fallbackTransfer.accountName,
    reference: fallbackTransfer.reference,
    amount_naira: fallbackTransfer.amountNaira,
    transfer_amount_naira: fallbackTransfer.transferAmountNaira,
    net_credit_naira: fallbackTransfer.netCreditNaira,
    expires_at: fallbackTransfer.expiresAt,
    _debug: {
      providers,
      customerCode,
    },
  });
}

async function handleTransferAccount(
  admin: Awaited<ReturnType<typeof createPaystackClient>>,
  config: NonNullable<ReturnType<typeof getServerConfig>>,
  user: { id: string; email: string },
  body: JsonMap,
): Promise<Response> {
  if (!hasValidPaystackKey(config.paystackSecretKey)) {
    return jsonResponse({ message: "Paystack wallet funding is not configured." }, 503);
  }
  const amount = Number(body.amount);
  if (!Number.isInteger(amount) || amount < 100 || amount > 1000000) {
    return jsonResponse({ message: "Enter an amount between ₦100 and ₦1,000,000." }, 400);
  }

  const { data: profile } = await admin
    .from("profiles")
    .select("full_name, phone")
    .eq("id", user.id)
    .maybeSingle();

  const { data: wallet } = await admin
    .from("wallets")
    .select("virtual_account_bank, paystack_customer_code")
    .eq("user_id", user.id)
    .maybeSingle();

  const account = await createBankTransferChargeAccount(
    admin,
    config.paystackSecretKey,
    user.id,
    user.email,
    amount,
    String(profile?.full_name ?? ""),
  );
  if (!account) {
    return jsonResponse({
      message: "Paystack could not generate a transfer account right now. Please try again.",
    }, 502);
  }

  // Keep the wallet's default Paystack-Titan account synchronized with this active transfer account
  if (!wallet?.virtual_account_bank || wallet.virtual_account_bank === "Paystack-Titan") {
    await admin.rpc("save_paystack_dedicated_wallet_account", {
      p_user_id: user.id,
      p_customer_code: String(wallet?.paystack_customer_code ?? ""),
      p_account_number: account.accountNumber,
      p_bank_name: account.bankName,
      p_account_name: account.accountName,
    });
  }

  return jsonResponse({
    status: "assigned",
    account_number: account.accountNumber,
    bank_name: account.bankName,
    account_name: account.accountName,
    reference: account.reference,
    amount_naira: account.amountNaira,
    transfer_amount_naira: account.transferAmountNaira,
    net_credit_naira: account.netCreditNaira,
    expires_at: account.expiresAt,
  });
}

async function syncCustomerPaystackTransfers(
  admin: Awaited<ReturnType<typeof createPaystackClient>>,
  secretKey: string,
  user: { id: string; email: string },
): Promise<{
  credited: boolean;
  reference: string;
  netNaira: number;
  grossNaira: number;
  feeNaira: number;
} | null> {
  // 1. Check recent pending or failed local wallet_fund transactions for this user
  const { data: recentLocal } = await admin
    .from("transactions")
    .select("reference, status")
    .eq("user_id", user.id)
    .eq("category", "wallet_fund")
    .eq("type", "credit")
    .in("status", ["pending", "failed"])
    .order("created_at", { ascending: false })
    .limit(6);

  if (Array.isArray(recentLocal)) {
    for (const row of recentLocal) {
      const ref = typeof row.reference === "string" ? row.reference : "";
      if (!ref) continue;
      try {
        const payment = await verifyPaystackTransaction(secretKey, ref);
        const amountKobo = Number(payment.amount);
        if (
          payment.status === "success" &&
          payment.currency === "NGN" &&
          Number.isSafeInteger(amountKobo) &&
          amountKobo > 0
        ) {
          const net = calculateNetFunding(payment);
          if (net.netNaira > 0) {
            const { data: creditRes, error } = await admin.rpc(
              "credit_paystack_wallet_funding",
              {
                p_user_id: user.id,
                p_reference: ref,
                p_amount: net.netNaira,
                p_narration: net.narration,
              },
            );
            if (!error && isRecord(creditRes) && creditRes.credited === true) {
              if (String(payment.channel) === "bank_transfer") {
                await rotateDefaultTransferAccountIfNeeded(admin, secretKey, user.id);
              }
              return {
                credited: true,
                reference: ref,
                netNaira: net.netNaira,
                grossNaira: net.grossNaira,
                feeNaira: net.feeNaira,
              };
            }
          }
        }
      } catch {
        // Ignore unverified reference
      }
    }
  }

  // 2. Also query Paystack's customer transactions directly in case Paystack assigned a new reference
  try {
    const customerRes = await paystackApiRequest(
      secretKey,
      `/customer/${encodeURIComponent(user.email.trim().toLowerCase())}`,
      "GET",
    );
    if (customerRes.ok && customerRes.body && isRecord(customerRes.body.data)) {
      const customerId = customerRes.body.data.id;
      const customerCode = getCustomerCode(customerRes.body.data) ?? "";
      if (typeof customerId === "number" || typeof customerId === "string") {
        const txListRes = await paystackApiRequest(
          secretKey,
          `/transaction?customer=${encodeURIComponent(String(customerId))}&status=success&perPage=10`,
          "GET",
        );
        const txList = Array.isArray(txListRes.body?.data) ? txListRes.body.data : [];
        for (const item of txList) {
          if (!isRecord(item)) continue;
          const ref = typeof item.reference === "string" ? item.reference.trim() : "";
          const amountKobo = Number(item.amount);
          if (
            !ref ||
            !/^[A-Za-z0-9_-]{8,100}$/.test(ref) ||
            item.status !== "success" ||
            item.currency !== "NGN" ||
            !Number.isSafeInteger(amountKobo) ||
            amountKobo <= 0
          ) {
            continue;
          }

          // Check if already completed in our DB
          const { data: existingTx } = await admin
            .from("transactions")
            .select("status")
            .eq("reference", ref)
            .maybeSingle();
          if (existingTx?.status === "completed") continue;

          const verified = await verifyPaystackTransaction(secretKey, ref);
          if (verified.status !== "success" || verified.currency !== "NGN") continue;

          const net = calculateNetFunding(verified);
          if (net.netNaira <= 0) continue;

          const { data: creditRes, error } = await admin.rpc(
            "credit_paystack_dedicated_wallet_funding",
            {
              p_user_id: user.id,
              p_customer_code: customerCode,
              p_reference: ref,
              p_amount: net.netNaira,
              p_narration: net.narration,
            },
          );
          if (!error && isRecord(creditRes) && creditRes.credited === true) {
            if (String(verified.channel) === "bank_transfer") {
              await rotateDefaultTransferAccountIfNeeded(admin, secretKey, user.id);
            }
            return {
              credited: true,
              reference: ref,
              netNaira: net.netNaira,
              grossNaira: net.grossNaira,
              feeNaira: net.feeNaira,
            };
          }
        }
      }
    }
  } catch (err) {
    console.error("Customer transaction sync check failed:", err);
  }

  return null;
}

async function handleVerify(
  admin: Awaited<ReturnType<typeof createPaystackClient>>,
  config: NonNullable<ReturnType<typeof getServerConfig>>,
  user: { id: string; email: string },
  body: JsonMap,
): Promise<Response> {
  if (!hasValidPaystackKey(config.paystackSecretKey)) {
    console.error("Paystack verification blocked because the configured key is not Live.");
    return jsonResponse({ message: "Paystack wallet funding is not configured." }, 503);
  }

  const reference = String(body.reference ?? "").trim();

  // If no specific reference was passed (verify_latest), scan all recent pending/customer transfers
  if (!reference) {
    const synced = await syncCustomerPaystackTransfers(
      admin,
      config.paystackSecretKey,
      user,
    );
    if (synced) {
      return jsonResponse({
        status: "completed",
        credited: true,
        reference: synced.reference,
        amount: synced.netNaira,
        gross_amount: synced.grossNaira,
        fee_amount: synced.feeNaira,
        currency: "NGN",
      });
    }
    return jsonResponse({ status: "none", credited: false });
  }

  if (!/^[A-Za-z0-9_-]{8,100}$/.test(reference)) {
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

  let payment: JsonMap;
  try {
    payment = await verifyPaystackTransaction(config.paystackSecretKey, reference);
  } catch (error) {
    console.error("Paystack transaction verification failed:", error);
    return jsonResponse({ message: "Payment is not confirmed yet. Please check again shortly." }, 503);
  }

  const amountKobo = Number(payment.amount);
  if (
    payment.reference !== reference ||
    payment.currency !== "NGN" ||
    !Number.isSafeInteger(amountKobo) ||
    amountKobo <= 0
  ) {
    console.error("Paystack verification details do not match a valid NGN payment.");
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

  const net = calculateNetFunding(payment);
  if (net.netNaira <= 0) {
    return jsonResponse({ message: "Payment amount is too small after fees." }, 409);
  }

  const { error: creditError } = await admin.rpc("credit_paystack_wallet_funding", {
    p_user_id: user.id,
    p_reference: reference,
    p_amount: net.netNaira,
    p_narration: net.narration,
  });
  if (creditError) {
    console.error("Paystack verification wallet credit failed:", creditError.message);
    return jsonResponse({ message: "Payment is confirmed but wallet update is delayed." }, 503);
  }

  if (String(payment.channel) === "bank_transfer") {
    await rotateDefaultTransferAccountIfNeeded(admin, config.paystackSecretKey, user.id);
  }

  return jsonResponse({
    status: "completed",
    credited: true,
    reference,
    amount: net.netNaira,
    gross_amount: net.grossNaira,
    fee_amount: net.feeNaira,
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

  const admin = await createPaystackClient(config.supabaseUrl, config.serviceRoleKey);

  const bearerToken = (request.headers.get("Authorization") ?? "")
    .replace(/^Bearer\s+/i, "")
    .trim();
  let isServiceRole = bearerToken === config.serviceRoleKey;
  if (!isServiceRole && bearerToken.split(".").length === 3) {
    try {
      const jwtPayload = JSON.parse(atob(bearerToken.split(".")[1]));
      if (isRecord(jwtPayload) && jwtPayload.role === "service_role") {
        isServiceRole = true;
      }
    } catch {
      isServiceRole = false;
    }
  }
  if (body.action === "provision_all_default_accounts" && isServiceRole) {
    const { data: profiles } = await admin
      .from("profiles")
      .select("id, email, full_name, phone");
    const provisioned: JsonMap[] = [];
    if (Array.isArray(profiles)) {
      for (const p of profiles) {
        if (!isRecord(p) || typeof p.id !== "string" || typeof p.email !== "string") continue;
        const res = await handleDedicatedAccount(
          admin,
          config,
          { id: p.id, email: p.email },
          { full_name: p.full_name, phone: p.phone },
        );
        const resBody: unknown = await res.json().catch(() => ({}));
        provisioned.push({
          user_id: p.id,
          email: p.email,
          result: isRecord(resBody) ? resBody : {},
        });
      }
    }
    return jsonResponse({ status: "ok", provisioned });
  }

  const user = await authenticateUser(request, config.supabaseUrl);
  if (!user) return jsonResponse({ message: "Authentication is required." }, 401);

  if (body.action === "initialize") {
    return await handleInitialize(admin, config, user, body);
  }
  if (body.action === "transfer_account") {
    return await handleTransferAccount(admin, config, user, body);
  }
  if (body.action === "dedicated_account") {
    return await handleDedicatedAccount(admin, config, user, body);
  }
  if (body.action === "verify" || body.action === "verify_latest") {
    return await handleVerify(admin, config, user, body);
  }
  return jsonResponse({ message: "Unsupported payment operation." }, 400);
});
