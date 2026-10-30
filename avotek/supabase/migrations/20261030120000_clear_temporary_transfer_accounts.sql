-- Temporary Paystack checkout accounts (Paystack-Titan / PAYSTACK CHECKOUT) expire and
-- must never be shown as a wallet's permanent dedicated account number.
UPDATE public.wallets
   SET virtual_account_number = NULL,
       virtual_account_bank = NULL,
       virtual_account_name = NULL,
       paystack_dva_status = 'unassigned',
       paystack_dva_requested_at = NULL,
       updated_at = NOW()
 WHERE virtual_account_bank = 'Paystack-Titan'
   AND virtual_account_name = 'PAYSTACK CHECKOUT';

-- Close abandoned pending funding rows (a late payment is still credited by the webhook).
DO $$
DECLARE
    pending_row RECORD;
BEGIN
    FOR pending_row IN
        SELECT user_id, reference
          FROM public.transactions
         WHERE category = 'wallet_fund'
           AND type = 'credit'
           AND status = 'pending'
    LOOP
        PERFORM public.fail_paystack_wallet_funding(pending_row.user_id, pending_row.reference);
    END LOOP;
END;
$$;
