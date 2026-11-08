# Mobile POS (Shell-First) — Implementation Plan

> **Status:** Implemented on 2026-11-08.

## 1. Goal

Give the mobile app a working POS operation page for tablets. The page uses the same Shell-First pattern as web: the server returns a minimal shell, and the existing POS Stimulus controller hydrates products, services, cart, payment, and receipt from JSON. Portrait tablets stack the order panel under the catalog; landscape tablets show the two-column layout.

## 2. Locked decisions

| Decision | Choice |
|---|---|
| Rendering approach | Shell-First for this screen only |
| Controller reuse | Reuse `Companies_Operations_Pos_ShowController`; do not duplicate POS logic |
| Hydration endpoint | Existing web JSON endpoint `/companies/:company_id/operations/pos/:operation_id.json` |
| Mobile path | `/mobile/companies/:company_id/operations/pos/:operation_id` |
| Orientation | Width-driven: `< lg` stacked, `>= lg` two columns (existing POS grid) |
| Mobile layout | No global mobile layout change in this task |

## 3. Current state

| File | Current role |
|---|---|
| `config/routes.rb` | Mobile company scope has only `operations#index`; no POS show route |
| `app/controllers/mobile/companies/operations_controller.rb` | Read-only operation appointment list |
| `app/views/mobile/companies/operations/index.html.erb` | Renders operation cards with no open action |
| `app/controllers/companies/operations/pos_controller.rb` | Web POS JSON hydration + customer lookup |
| `app/javascript/controllers/companies/operations/pos/show_controller.js` | POS cart/payment/receipt state machine; reads company id from `pathname[2]` |
| `app/views/layouts/application.html.erb` | Web shell wrapper carries `data-controller` and `data-operation-id` |
| `app/views/layouts/mobile.html.erb` | Mobile layout yields content; no `data-controller` wrapper |

## 4. Target behavior

- Mobile Operations list exposes an **Open POS** action for POS operations.
- The POS route authenticates the operation, resolves the branch appointment, and renders a minimal shell.
- The POS Stimulus controller reads `data-company-id` / `data-operation-id` from its mount element, fetches JSON, and renders the full POS UI.
- Existing web POS path keeps working unchanged (data-attribute fallback to `pathname[2]`).
- Failure states redirect to the mobile Operations list with an alert.

## 5. Backend contract

- Mobile route helper: `mobile_company_pos_path(company, operation)`.
- Shell mount element:
  - `data-controller="companies--operations--pos--show darkmode"`
  - `data-company-id`
  - `data-operation-id`
- JSON payload reuses `Companies::Operations::PosController#show` (`operation`, `appointment`, `config`, `products`, `services`, `payment_methods`).

## 6. Implementation steps

1. Add the mobile POS route inside the mobile company scope.
2. Add `Mobile::Companies::Operations::PosController` with operation/appointment resolution and access checks.
3. Add `Mobile::Companies::Operations::PosPolicy#show?`.
4. Add the shell view `mobile/companies/operations/pos/show.html.erb`.
5. Update `show_controller.js` to read company id from `data-company-id` (fallback to `pathname[2]`).
6. Add the **Open POS** link to the mobile Operations list.
7. Update `docs/MOBILE.md` and `docs/MOBILE_FEATURE_MATRIX.md`.
8. Add mobile POS feature coverage and run web POS regression coverage.

## 7. Tests

### Feature specs (primary proof)

- Mobile POS shell renders and hydrates the catalog.
- Add-to-cart works from the mobile POS page.
- ORDER → payment → receipt works from the mobile page.
- Operations list opens the POS page.
- Non-POS operation has no POS link.
- Missing/inactive appointment redirects to mobile Operations.
- Portrait tablet stacks the order panel under the catalog.
- Landscape tablet shows the order panel beside the catalog.
- POS header dark-mode toggle persists to `localStorage`.

### Regression

- `spec/features/companies/operations/pos_spec.rb` stays green.

## 8. Verification commands

```bash
bundle exec parallel_rspec -n 14 spec/features/mobile/pos_spec.rb spec/features/mobile/operations_spec.rb spec/features/companies/operations/pos_spec.rb
bin/rubocop
bin/check_colors --strict
```
