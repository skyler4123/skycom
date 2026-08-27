# TODO — Undecided / Future Work

## Transaction Token Naming

`Transaction.gateway_reference` (DB column, value e.g. `POS_<hex>`) is exposed as `transaction_token` in the API/service layer (`V1Controller#pay` response, `pay_cancel` param, `InitiatePaymentService::Result`, `CancelPaymentService`). The seam `Transaction.find_by!(gateway_reference: transaction_token, company_id: company.id)` makes the inconsistency explicit. Unify to one canonical name later (rename column or param + migrate callers).

## BE↔FE Controller Link Comments

Expand link headers (Serves Stimulus / Depends on BE) to remaining `Companies::*` controllers + their Stimulus pairs. Follow the template added to `V1Controller`, `OrdersController`, `PagesController`, `MockQrGatewayController`, `RetailCashierController`, and `TopUps::NewController` — file header lists counterpart + endpoints + docs.

## Payment Method "Configured" Logic

The Banking column on the index page uses `merchant_number || merchant_name || merchant_id` to determine if a payment method is "Configured". This heuristic is not final — it's unclear which of these three fields are truly required vs optional.

For example, a `redirect`-mode gateway (Stripe) might only need a `merchant_id` (API terminal ID), not a bank account number or holder name. But the current OR logic would mark it "Configured" with just an ID filled, which might be confusing since the user sees an empty "Bank Account Number" field on the same record.

**Needs decision:**
- Define per-payment-mode required fields (e.g., `qr` → merchant_number + merchant_name required; `redirect` → merchant_id only)
- Update the `Configured` / `Not Set` badge logic to only check required fields for each mode
- Possibly add inline hints in the edit form showing which fields are required per mode

## Low-Stock Alert Threshold

The stocks table previously used the `reorder` column as a minimum-stock threshold (red highlight when `quantity <= reorder`). The column was renamed to `pending` with proper reserved-units semantics (`docs/ORDER_PROCESSING_V1.md` §7), so low-stock highlighting was removed.

**Needs decision:**
- If low-stock alerts are wanted again, add a dedicated `min_stock` column (threshold semantics, never decremented by the order pipeline)
