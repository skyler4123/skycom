# frozen_string_literal: true

# Companies::Operations::InventoryController — the Inventory operation.
# Hydrates the live stock ledger, vital inventory metrics, freight dock
# activity, zone capacity and audit summary for the resolved warehouse
# appointment.
#
# Serves Stimulus: Companies_Operations_Inventory_ShowController
# Endpoints: GET /companies/:company_id/operations/inventory/:operation_id
# Docs: docs/OPERATIONS.md, docs/STOCK.md
class Companies::Operations::InventoryController < Companies::Operations::BaseController
  private

  def expected_operation_type
    :inventory
  end

  def operation_payload
    {
      coming_soon: false,
      inventory: Inventory::ConsoleService.call(
        company: current_company,
        appointment: @appointment
      )
    }
  end
end
