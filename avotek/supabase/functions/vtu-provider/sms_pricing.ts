export function calculateSmsRetailPrice(
  providerCostPerPage: number,
  multiplier = 1,
): number {
  if (!Number.isFinite(providerCostPerPage) || providerCostPerPage <= 0) {
    throw new RangeError("SMS provider cost must be greater than zero.");
  }
  const safeMultiplier = Number.isFinite(multiplier)
    ? Math.min(1.15, Math.max(1, multiplier))
    : 1;
  return Math.max(7, Math.ceil(providerCostPerPage * safeMultiplier - 1e-8));
}
