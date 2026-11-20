# Skycom Index Export (CSV)

## Overview
Every index page can optionally show an **Export** button (header, visible only when the page is enabled in `EXPORT_ENABLED_RESOURCES`). Clicking it fetches the full filtered record set and downloads a CSV built in the browser.

## Skycom-level toggle
- `EXPORT_ENABLED_RESOURCES` in `config/initializers/constants.rb` — array of resource keys (URL/controller name).
- Skycom edits this constant to enable/disable export for a page for all companies.
- The list is exposed via `/client_cache` as `export_pages` and cached client-side (`exportEnabled(resource)`).

## Backend
- Guard: `Companies::ApplicationController#ensure_export_enabled` runs when `params[:export]` is present and rejects disabled pages with `422 { errors: [...] }`.
- Optimized path: controllers may add an export branch to `index` to return all records at once:
  ```ruby
  if params[:export].present?
    results = scope.to_a
    if results.size > EXPORT_MAX_RECORDS
      render json: { errors: [ "Export exceeds maximum of #{EXPORT_MAX_RECORDS} records" ] }, status: :unprocessable_content and return
    end
    render json: { products: format_products(results) } and return
  end
  ```
- Otherwise the frontend paginates through the normal index endpoint.

## Frontend
- `Companies_LayoutController#exportCSV()` (inherited by all pages) handles fetch + CSV + download.
- `Helpers.exportEnabled(resource)` / `Helpers.downloadCSV(records, columns, filename)`.
- Button renders in the layout header only on index pages (`/companies/:id/:resource`) when enabled.

## Operation consoles (Inventory ledger)
Operation consoles export their own filtered view instead of using the index pipeline:

- `GET /companies/:company_id/operations/inventory/:operation_id/ledger` (`Companies::Operations::InventoryController#ledger`) — CSV, `send_data`.
- It reuses `Inventory::LedgerScope` so the file contains exactly the rows the current tab + search show (all matching rows, not the capped screen page).
- The attachment filename includes the warehouse code and the selected bucket: `inventory-<warehouse-code>-<bucket>-<location-date>.csv`.
- It is **not** gated by `EXPORT_ENABLED_RESOURCES` (that toggle governs index pages), but it honors `EXPORT_MAX_RECORDS` and returns `{ errors: [...] }` with `:unprocessable_content` above it.
- Proof: `spec/requests/companies/operations/inventory_spec.rb` (filtered bucket, cap, oversized refusal).

## File reference
- `config/initializers/constants.rb` — `EXPORT_ENABLED_RESOURCES`, `EXPORT_MAX_RECORDS`
- `app/controllers/companies/application_controller.rb` — guard
- `app/controllers/client_cache_controller.rb` — `export_pages`
- `app/javascript/controllers/companies/layout_controller.js` — `exportCSV()` + header button
- `app/javascript/controllers/helpers/auth_helpers.js` — `exportEnabled`
- `app/javascript/controllers/helpers/ui_helpers.js` — `downloadCSV`