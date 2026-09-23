# frozen_string_literal: true

# Executes a StockImport: one `add` ledger row per StockItemAppointment line
# (transaction_type: import, appoint_for: import). Add direction has no floor
# constraint — imports always succeed when the document and lines are valid.
# The document transitions pending → received in the same transaction.
class StockMovementService::Imports::CreateService < StockMovementService::BaseService
  # Executes the whole flow for a freshly-built import:
  #   ActiveRecord::Base.transaction do
  #     StockMovementService::Imports::CreateService.execute!(document: document, employee: employee)
  #   end
  # Raises StockMovementService::Error on invalid state → caller's transaction
  # rolls back document + lines + ledger + quantity together.
  def self.execute!(document:, employee:)
    raise StockMovementService::Error, "Import has no stock lines" if document.stock_item_appointments.empty?

    document.stock_item_appointments.each do |line|
      call(
        stock: line.stock,
        quantity: line.quantity,
        direction: :add,
        transaction_type: :import,
        document: document,
        employee: employee
      )
    end

    document.update!(workflow_status: :received)
    document
  end
end
