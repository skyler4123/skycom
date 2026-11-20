# frozen_string_literal: true

# Companies::Operations::InventoryController — the Inventory operation.
# Hydrates the one-page warehouse console (stock-row and low/out KPIs, the
# searchable stock ledger with disjoint availability tabs, the recent receipt
# and dispatch record lists, and the cycle-count gap) for the resolved
# warehouse appointment, and serves the filtered ledger as a CSV download.
#
# Serves Stimulus: Companies_Operations_Inventory_ShowController
# Endpoints: GET /companies/:company_id/operations/inventory/:operation_id
#            GET /companies/:company_id/operations/inventory/:operation_id/ledger(.csv)
# Docs: docs/OPERATIONS.md, docs/STOCK.md, docs/business_analysis/05-inventory.md
class Companies::Operations::InventoryController < Companies::Operations::BaseController
  def ledger
    scope = Inventory::LedgerScope.new(
      company: current_company,
      appointment: @appointment,
      q: params[:q],
      bucket: params[:bucket]
    )

    if scope.total > EXPORT_MAX_RECORDS
      return render json: { errors: [ "Export exceeds maximum of #{EXPORT_MAX_RECORDS} records" ] },
        status: :unprocessable_content
    end

    send_data Inventory::LedgerCsv.call(rows: scope.export_rows, currency: current_company.currency || "usd"),
      filename: "inventory-#{scope.warehouse_code}-#{scope.bucket}-#{LocalTime.today(scope.warehouse || scope.branch)}.csv",
      type: "text/csv; charset=utf-8"
  end

  private

  def expected_operation_type
    :inventory
  end

  def operation_payload
    {
      coming_soon: false,
      inventory: Inventory::ConsoleService.call(
        company: current_company,
        appointment: @appointment,
        q: params[:q],
        bucket: params[:bucket]
      )
    }
  end
end
