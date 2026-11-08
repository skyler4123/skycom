# frozen_string_literal: true

# Companies::Operations::StoreManagerController — the Store Manager operation.
# Hydrates the resolved BranchOperationAppointment with the branch's live stock
# directory, inbound StockImport documents, outbound StockExport documents and
# the KPI strip derived from them.
# Serves Stimulus: Companies_Operations_StoreManager_ShowController (store console)
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
      store_manager: StoreManager::ConsoleService.call(company: current_company, appointment: @appointment)
    }
  end
end
