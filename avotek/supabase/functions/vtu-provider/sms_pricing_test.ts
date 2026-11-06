import { calculateSmsRetailPrice } from "./sms_pricing.ts";

function assertEqual(actual: number, expected: number): void {
  if (actual !== expected) {
    throw new Error(`Expected ${expected}, received ${actual}.`);
  }
}

Deno.test("bulk SMS has a minimum retail price of seven naira per page", () => {
  assertEqual(calculateSmsRetailPrice(6.5), 7);
  assertEqual(calculateSmsRetailPrice(3.5), 7);
});

Deno.test("bulk SMS retail price rounds up above provider cost", () => {
  assertEqual(calculateSmsRetailPrice(7.1), 8);
  assertEqual(calculateSmsRetailPrice(7.1, 1.1), 8);
});

Deno.test("bulk SMS pricing rejects invalid provider costs", () => {
  let didThrow = false;
  try {
    calculateSmsRetailPrice(0);
  } catch (error) {
    didThrow = error instanceof RangeError;
  }
  if (!didThrow) throw new Error("Expected an invalid SMS cost to be rejected.");
});
