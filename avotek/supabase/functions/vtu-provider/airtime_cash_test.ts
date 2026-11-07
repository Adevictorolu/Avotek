import { assertEquals, assertThrows } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  calculateAirtimeCashPayout,
  normalizeAirtimeCashPhone,
} from "./airtime_cash.ts";

Deno.test(
  "airtime cash phone normalization accepts local and international input",
  () => {
    assertEquals(normalizeAirtimeCashPhone("08012345678"), "2348012345678");
    assertEquals(normalizeAirtimeCashPhone("+234 801 234 5678"), "2348012345678");
  },
);

Deno.test("airtime cash payout uses the MTN rate", () => {
  assertEquals(calculateAirtimeCashPayout(1, 1000), 850);
});

Deno.test("airtime cash payout uses the Airtel rate", () => {
  assertEquals(calculateAirtimeCashPayout(2, 1000), 820);
});

Deno.test("airtime cash rejects unsupported networks and amounts", () => {
  assertThrows(() => calculateAirtimeCashPayout(3, 1000), RangeError);
  assertThrows(() => calculateAirtimeCashPayout(1, 500), RangeError);
  assertThrows(() => calculateAirtimeCashPayout(1, 1001.5), RangeError);
});
