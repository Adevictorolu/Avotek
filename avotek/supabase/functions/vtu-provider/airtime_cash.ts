export function normalizeAirtimeCashPhone(phone: unknown): string {
  const digits = String(phone ?? "").trim().replace(/\D+/g, "");
  if (digits.startsWith("0") && digits.length === 11) {
    return `234${digits.slice(1)}`;
  }
  return digits;
}

export function calculateAirtimeCashPayout(
  networkId: number,
  airtimeAmount: number,
): number {
  if (
    !Number.isInteger(airtimeAmount) ||
    airtimeAmount < 1000 ||
    airtimeAmount > 50000
  ) {
    throw new RangeError("Airtime amount must be between ₦1,000 and ₦50,000.");
  }
  const rate = networkId === 1 ? 0.85 : networkId === 2 ? 0.82 : null;
  if (rate === null) {
    throw new RangeError("Airtime to Cash supports MTN and Airtel only.");
  }
  return Math.round(airtimeAmount * rate);
}
