# frozen_string_literal: true

# Companies::Operations::StoreManagerController — the Store Manager operation.
# Hydrates the resolved BranchOperationAppointment, then exposes the live
# retail command payload (today's sales KPIs, fulfillment queue, shelf
# replenishment alerts, register activity, hourly order volume and on-duty
# roster) built from Orders, Stocks and Employees.
#
# Serves Stimulus: Companies_Operations_StoreManager_ShowController
# Endpoints: GET /companies/:company_id/operations/store_manager/:operation_id
# Docs: docs/OPERATIONS.md, docs/STOCK.md
class Companies::Operations::StoreManagerController < Companies::Operations::BaseController
  private

  def expected_operation_type
    :store_manager
  end

  def operation_payload
    {
      coming_soon: false,
      store_manager: StoreManager::ConsoleService.call(
        company: current_company,
        appointment: @appointment
      )
    }
  end
end
